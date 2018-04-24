
  extern platform_panic
  extern platform_exit
  extern platform_open_file
  extern platform_reset_file
  extern platform_read_char

  TERM_ROW_NUM equ 25
  TERM_COL_NUM equ 80
  TERM_BASE_ADDR equ 0xb8000

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

stack:
  resb 1024
stack_top:

term_row:
  resd 1

term_col:
  resd 1

str_helloasm:
  db 'Hello, ASM!'
  db 0xa
  db 0

start_from_multiboot:
  ;; Set up stack (aligned to 16 bytes)
  mov esp, stack_top
  and esp, 0xfffffff0

  call term_setup

  ;; Greetings!
  push str_helloasm
  push 1
  call platform_log
  add esp, 8

  ;; Try itoa
  push 2204
  call itoa
  add esp, 4
  push eax
  push 1
  call platform_log
  add esp, 8

  call loop_forever


loop_forever:
  jmp loop_forever


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


platform_write_char:
  ;; Switch depending on the requested file descriptor
  mov eax, [esp+4]
  cmp eax, 1
  je platform_write_char_stdout
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
