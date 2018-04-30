
  STACK_SIZE equ 65536

  TERM_ROW_NUM equ 25
  TERM_COL_NUM equ 80
  TERM_BASE_ADDR equ 0xb8000

  MAX_OPEN_FILE_NUM equ 1024

  MBMAGIC equ 0x1badb002
  ;; Set flags for alignment, memory map and load adds
  MBFLAGS equ 0x10003
  ;; 0x100000000 - MBMAGIC - MBFLAGS
  MBCHECKSUM equ 0xe4514ffb

  ;; MB_ENTRY_ADDR equ _start

  ;; Multiboot header
  dd MBMAGIC
  dd MBFLAGS
  dd MBCHECKSUM

  dd 0x100000
  dd 0x100000
  dd 0x0
  dd 0x0
  dd 0x100020

  jmp start_from_multiboot

term_row:
  resd 1

term_col:
  resd 1

heap_ptr:
  resd 1

open_files:
  resd 1

open_file_num:
  resd 1

write_mem_ptr:
  resd 1

str_exit:
  db 'The execution has finished, bye bye...'
  db NEWLINE
  db 0
str_panic:
  db 'PANIC!'
  db NEWLINE
  db 0

str_init_heap_stack:
  db 'Initializing heap and stack... '
  db 0
str_init_files:
  db 'Initializing files table... '
  db 0
str_init_asm_symbols_table:
  db 'Initializing assembler and symbols table... '
  db 0
str_init_assemble_main:
  db 'Will now assemble main.asm...'
  db NEWLINE
  db 0
str_init_launch_main:
  db 'Will now call main!'
  db NEWLINE
  db 0
str_done:
  db 'done!'
  db NEWLINE
  db 0

str_END:
  db 'END'
  db 0

str_main_asm:
  db 'main.asm'
  db 0
str_main:
  db 'main'
  db 0

temp_stack:
  resb 128
temp_stack_top:

start_from_multiboot:
  ;; Setup a temporary stack
  mov esp, temp_stack_top
  and esp, 0xfffffff0

  ;; Initialize terminal
  call term_setup

  ;; Log
  push str_init_heap_stack
  push 1
  call platform_log
  add esp, 8

  ;; Find the end of the ar initrd
  push 0
  mov edx, esp
  push 0
  mov ecx, esp
  push edx
  push ecx
  push str_END
  call walk_initrd
  add esp, 12
  add esp, 4
  pop ecx

  ;; Initialize the heap
  mov eax, heap_ptr
  sub ecx, 1
  or ecx, 0xf
  add ecx, 1
  mov [eax], ecx

  ;; Allocate the stack on the heap
  add ecx, STACK_SIZE
  mov [eax], ecx
  mov esp, ecx

  ;; Log
  push str_done
  push 1
  call platform_log
  add esp, 8

  ;; Log
  push str_init_files
  push 1
  call platform_log
  add esp, 8

  ;; Initialize file table
  mov eax, open_file_num
  mov DWORD [eax], 0
  mov eax, MAX_OPEN_FILE_NUM
  mov edx, 12
  mul edx
  push eax
  call platform_allocate
  add esp, 4
  mov edx, open_files
  mov [edx], eax

  ;; Log
  push str_done
  push 1
  call platform_log
  add esp, 8

  ;; Log
  push str_init_asm_symbols_table
  push 1
  call platform_log
  add esp, 8

  ;; Init symbol table
  call init_symbols

  ;; Init assembler
  call init_assembler

  ;; Expose some kernel symbols
  call init_kernel_api

  ;; Log
  push str_done
  push 1
  call platform_log
  add esp, 8

  ;; Log
  push str_init_assemble_main
  push 1
  call platform_log
  add esp, 8

  ;; Assemble main.asm
  push str_main_asm
  call platform_assemble
  add esp, 4

  ;; Log
  push str_init_launch_main
  push 1
  call platform_log
  add esp, 8

  ;; Call main
  push 0
  push str_main
  call platform_get_symbol
  add esp, 8
  call eax

  call platform_exit


  ;; void platform_assemble(char *filename)
platform_assemble:
  ;; Prepare to write in memory
  mov eax, write_mem_ptr
  mov ecx, heap_ptr
  mov edx, [ecx]
  mov [eax], edx

  ;; Load the parameter and save some registers
  mov eax, [esp+4]
  push edx
  push edx

  ;; Open the file
  push eax
  call platform_open_file
  add esp, 4
  pop edx

  ;; Assemble the file
  push edx
  push 0
  push eax
  call assemble
  add esp, 12

  ;; Actually allocate used heap memory, so that new allocations will
  ;; not overwrite it
  mov eax, write_mem_ptr
  mov ecx, heap_ptr
  mov edx, [eax]
  sub edx, [ecx]
  push edx
  call platform_allocate
  add esp, 4

  ;; Assert that the allocation gave us what we expected
  pop edx
  cmp edx, eax
  jne platform_panic

  ret


  ;; void term_setup()
term_setup:
  ;; Compute the size of the VGA framebuffer
  mov eax, TERM_ROW_NUM
  mov edx, TERM_COL_NUM
  mul edx

  ;; Fill the VGA framebuffer with spaces char, with color light grey
  ;; 	on black
  mov ecx, TERM_BASE_ADDR
term_setup_loop:
  cmp eax, 0
  je term_setup_after_loop
  mov BYTE [ecx], SPACE
  mov BYTE [ecx+1], 0x07
  add ecx, 2
  sub eax, 1
  jmp term_setup_loop

term_setup_after_loop:
  ;; Set the cursor position
  mov eax, term_row
  mov DWORD [eax], 0
  mov eax, term_col
  mov DWORD [eax], 0

  ret


  ;; void term_set_char(int row, int col, int char)
term_set_char:
  ;; Computer the character address
  mov eax, [esp+4]
  mov edx, TERM_COL_NUM
  mul edx
  add eax, [esp+8]
  mov edx, 2
  mul edx
  add eax, TERM_BASE_ADDR

  ;; Store the new character
  mov dl, [esp+12]
  mov BYTE [eax], dl

  ret


  ;; void term_shift()
term_shift:
  push ebx

  ;; Compute the size of an entire row (stored in ecx)
  mov eax, TERM_COL_NUM
  mov edx, 2
  mul edx
  mov ecx, eax

  ;; Compute the size of all rows (stored in eax)
  mov edx, TERM_ROW_NUM
  mul edx

  ;; Store begin (ecx) and end (eax) of the buffer to copy, and the
  ;; pointer to which to copy (edx)
  add ecx, TERM_BASE_ADDR
  add eax, TERM_BASE_ADDR
  mov edx, TERM_BASE_ADDR

  ;; Copy loop
term_shift_loop:
  cmp ecx, eax
  je term_shift_after_loop
  mov bl, [ecx]
  mov [edx], bl
  add ecx, 1
  add edx, 1
  jmp term_shift_loop

term_shift_after_loop:
  mov ecx, edx
  mov eax, TERM_COL_NUM

  ;; Clear last line
term_shift_loop2:
  cmp eax, 0
  je term_shift_ret
  mov BYTE [ecx], SPACE
  mov BYTE [ecx+1], 0x07
  sub eax, 1
  add ecx, 2
  jmp term_shift_loop2

term_shift_ret:
  pop ebx
  ret


  ;; void term_put_char(int char)
term_put_char:
  ;; If the character is a newline, jump to the newline code
  mov ecx, [esp+4]
  cmp cl, NEWLINE
  je term_put_char_newline

  ;; Call term_set_char with the current position
  push ecx
  mov edx, term_col
  mov eax, [edx]
  push eax
  mov edx, term_row
  mov eax, [edx]
  push eax
  call term_set_char
  add esp, 12

  ;; Advance of one character
  mov edx, term_col
  mov eax, [edx]
  add eax, 1
  mov [edx], eax

  ;; Check for column overflow
  cmp eax, TERM_COL_NUM
  jne term_put_char_finish

  ;; Move to the beginning of next row
term_put_char_newline:
  mov edx, term_col
  mov DWORD [edx], 0
  mov edx, term_row
  mov eax, [edx]
  add eax, 1
  mov [edx], eax

  ;; Check for row overflow
  cmp eax, TERM_ROW_NUM
  jne term_put_char_finish

  ;; Reset the row position and shift all lines
  sub eax, 1
  mov [edx], eax
  call term_shift

term_put_char_finish:
  ret


loop_forever:
  jmp loop_forever


platform_exit:
  ;; Write an exit string
  push str_exit
  push 1
  call platform_log
  add esp, 8

  jmp loop_forever


platform_panic:
  ;; Write an exit string
  push str_panic
  push 1
  call platform_log
  add esp, 8

  jmp loop_forever


platform_write_char:
  ;; Switch depending on the requested file descriptor
  mov eax, [esp+4]
  cmp eax, 0
  je platform_write_char_mem
  cmp eax, 1
  je platform_write_char_stdout
  cmp eax, 2
  je platform_write_char_stdout
  ret

platform_write_char_mem:
  ;; Write to memory and update pointer
  mov eax, [esp+8]
  mov ecx, write_mem_ptr
  mov edx, [ecx]
  mov [edx], al
  add edx, 1
  mov [ecx], edx
  ret

platform_write_char_stdout:
  ;; Send stdout to terminal
  mov eax, [esp+8]
  push eax
  call term_put_char
  add esp, 4
  ret


platform_log:
  ;; Use ebx for the fd and esi for the string
  mov eax, [esp+4]
  mov edx, [esp+8]
  push ebx
  push esi
  mov ebx, eax
  mov esi, edx

  ;; Loop over the string and call platform_write_char
platform_log_loop:
  mov ecx, 0
  mov cl, [esi]
  cmp cl, 0
  je platform_log_loop_ret
  push ecx
  push ebx
  call platform_write_char
  add esp, 8
  add esi, 1
  jmp platform_log_loop

platform_log_loop_ret:
  pop esi
  pop ebx
  ret


  ;; void *platform_allocate(int size)
platform_allocate:
  ;; Prepare to return the current heap_ptr
  mov ecx, heap_ptr
  mov eax, [ecx]

  ;; Add the new size to the heap_ptr and realign
  mov edx, [esp+4]
  add edx, [ecx]
  sub edx, 1
  or edx, 0xf
  add edx, 1
  mov [ecx], edx

  ret


platform_open_file:
  ;; Find the new file record
  mov eax, open_file_num
  mov eax, [eax]
  mov edx, 12
  mul edx
  mov ecx, open_files
  add eax, [ecx]

  ;; ;; Call walk_initrd
  mov edx, [esp+4]
  mov ecx, eax
  add ecx, 8
  push eax
  push ecx
  push eax
  push edx
  call walk_initrd
  add esp, 12

  ;; Reset it to the beginning
  pop eax
  mov ecx, [eax]
  mov [eax+4], ecx

  ;; Return and increment the open file number
  mov ecx, open_file_num
  mov eax, [ecx]
  add DWORD [ecx], 1

  ret


platform_reset_file:
  ;; Find the file record
  mov eax, [esp+4]
  mov edx, 12
  mul edx
  mov ecx, open_files
  add eax, [ecx]

  ;; Reset it to the beginning
  mov ecx, [eax]
  mov [eax+4], ecx

  ret


platform_read_char:
  ;; Find the file record
  mov eax, [esp+4]
  mov edx, 12
  mul edx
  mov ecx, open_files
  add eax, [ecx]

  ;; Check if we are at the end
  mov ecx, [eax+4]
  cmp ecx, [eax+8]
  je platform_read_char_eof

  ;; Return a character and increment pointer
  mov edx, 0
  mov dl, [ecx]
  add DWORD [eax+4], 1
  mov eax, edx
  ret

platform_read_char_eof:
  ;; Return -1
  mov eax, 0xffffffff
  ret


str_platform_panic:
  db 'platform_panic'
  db 0
str_platform_exit:
  db 'platform_exit'
  db 0
str_platform_open_file:
  db 'platform_open_file'
  db 0
str_platform_read_char:
  db 'platform_read_char'
  db 0
str_platform_write_char:
  db 'platform_write_char'
  db 0
str_platform_log:
  db 'platform_log'
  db 0
str_platform_allocate:
  db 'platform_allocate'
  db 0
str_platform_assemble:
  db 'platform_assemble'
  db 0
str_platform_get_symbol:
  db 'platform_get_symbol'
  db 0

  ;; Initialize the symbols table with the "kernel API"
init_kernel_api:
  push 0
  push platform_panic
  push str_platform_panic
  call add_symbol
  add esp, 12

  push 0
  push platform_exit
  push str_platform_exit
  call add_symbol
  add esp, 12

  push 1
  push platform_open_file
  push str_platform_open_file
  call add_symbol
  add esp, 12

  push 1
  push platform_read_char
  push str_platform_read_char
  call add_symbol
  add esp, 12

  push 2
  push platform_write_char
  push str_platform_write_char
  call add_symbol
  add esp, 12

  push 2
  push platform_log
  push str_platform_log
  call add_symbol
  add esp, 12

  push 1
  push platform_allocate
  push str_platform_allocate
  call add_symbol
  add esp, 12

  push 1
  push platform_assemble
  push str_platform_assemble
  call add_symbol
  add esp, 12

  push 2
  push platform_get_symbol
  push str_platform_get_symbol
  call add_symbol
  add esp, 12

  ret


  ;; int platform_get_symbol(char *name, int *arity)
  ;; similar as find_symbol, but panic if it does not exist; retuns
  ;; the location and put the arity in *arity if arity is not null
platform_get_symbol:
  ;; Call find_symbol
  mov eax, [esp+4]
  mov ecx, [esp+8]
  push 0
  mov edx, esp
  push ecx
  push edx
  push eax
  call find_symbol
  add esp, 12

  ;; Panic if it does not exist
  cmp eax, 0
  je platform_panic

  ;; Return the symbol location
  pop eax

  ret
