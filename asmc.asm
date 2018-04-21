
  extern platform_panic
  extern platform_exit
  extern platform_open_file
  extern platform_reset_file
  extern platform_read_char
  extern platform_write_char
  extern platform_log

  extern assemble_file

  testequ equ 100

  NEWLINE equ 0xa
  SPACE equ 0x20
  TAB equ 0x9

  INPUT_BUF_LEN equ 1024
  MAX_SYMBOL_NAME_LEN equ 128
  SYMBOL_TABLE_LEN equ 1024
  ;; SYMBOL_TABLE_SIZE = SYMBOL_TABLE_LEN * MAX_SYMBOL_NAME_LEN
  SYMBOL_TABLE_SIZE equ 131072

section .bss

input_buf:
  resb 1024

symbol_names:
  resb SYMBOL_TABLE_SIZE

symbol_loc:
  resd SYMBOL_TABLE_LEN

symbol_num:
  resd 1

current_section:
  resb MAX_SYMBOL_NAME_LEN

current_loc:
  resd 1

stage:
  resd 1

section .text

  global  _start
_start:
  call assemble_file
  call platform_exit

  global get_input_buf
get_input_buf:
  mov eax, input_buf
  ret

  global get_symbol_names
get_symbol_names:
  mov eax, symbol_names
  ret

  global get_symbol_loc
get_symbol_loc:
  mov eax, symbol_loc
  ret

  global get_symbol_num
get_symbol_num:
  mov eax, symbol_num
  ret

  global get_current_section
get_current_section:
  mov eax, current_section
  ret

  global get_current_loc
get_current_loc:
  mov eax, current_loc
  ret

  global get_stage
get_stage:
  mov eax, stage
  ret

main_loop:
  push 0
  call platform_read_char
  add esp, 4
  cmp eax, 0xffffffff
  jz main_loop_finish
  push eax
  push 1
  call platform_write_char
  add esp, 4
  jmp main_loop

main_loop_finish:
  call platform_exit

_test:
  pop eax
  add eax, [eax+0x100]
  add [eax+0x200], eax
  add ebx, eax
  add eax, eax
  add [eax+0x300], ecx
  sub [eax+0x300], ecx
  jmp eax
  jmp [eax]

  jmp _test2
  call _test2

  jmp testequ2
  mov ecx, testequ
  mov [edx+testequ2], ebx

  testequ2 equ 2204

  jnz 0x100

_test2:
  jmp _test2
  jmp _test

_assemble_stdin:
  push ebp
  mov ebp, esp

  push 1024
  ;; push input_buf
  push 0
  call readline
  add esp, 12

  pop ebp
  ret

_platform_exit:
  ;; Just exit, never return
  mov ebx, 0
  mov eax, 1
  int 0x80

_platform_write_char:
  ;; Write the char in AL to output
  push ebx
  sub esp, 4
  and eax, 0xff
  mov [esp], eax

  mov edx, 1
  mov ecx, esp
  mov ebx, 1
  mov eax, 4
  int 0x80

  cmp eax, 1
  jnz platform_panic

  add esp, 4
  pop ebx
  ret


_platform_read_char:
  ;;  Read a char from input to AL; all other bits of EAX are zeroed; if the file is finished, put 0xffffffff in EAX
  push ebx
  sub esp, 4
  mov DWORD [esp], 0

  mov edx, 1
  mov ecx, esp
  mov ebx, 0
  mov eax, 3
  int 0x80

  cmp eax, 0
  jz _platform_read_char_file_finished

  cmp eax, 1
  jnz platform_panic

  mov eax, [esp]
  add esp, 4
  pop ebx
  ret

_platform_read_char_file_finished:
  mov eax, 0xffffffff
  add esp, 4
  pop ebx
  ret

_platform_panic:
  ;; Forcibly abort the execution in consequence of an error
  call 0

  global assert
assert:
  cmp DWORD [esp+4], 0
  jnz assert_return
  call platform_panic
assert_return:
  ret


  global readline
readline:
  push ebp
  mov ebp, esp
readline_begin_loop:
  ;; If len is zero, jump to panic
  cmp DWORD [ebp+16], 0
  jz platform_panic

  ;; Call platform_read_char
  mov ecx, [ebp+8]
  push ecx
  call platform_read_char
  add esp, 4

  ;; Store the buffer address in edx
  mov edx, [ebp+12]

  ;; Handle newline and eof
  cmp eax, NEWLINE
  jz readline_newline_found
  cmp eax, 0xffffffff
  jz readline_eof_found

  ;; Copy a byte
  mov [edx], al

  ;; Increment the buffer and decrement the length
  add edx, 1
  mov [ebp+12], edx
  mov ecx, [ebp+16]
  sub ecx, 1
  mov [ebp+16], ecx

  jmp readline_begin_loop

  ;; On newline, store the string terminator and return 0
readline_newline_found:
  mov BYTE [edx], 0
  mov eax, 0
  jmp readline_ret

  ;; On eof, store the string terminator and return 1
readline_eof_found:
  mov BYTE [edx], 0
  mov eax, 1
  jmp readline_ret

readline_ret:
  pop ebp
  ret


  global trimstr
trimstr:
  ;; Load registers (eax for writing, ecx for reading)
  mov eax, [esp+4]
  mov ecx, eax

  ;; Skip the initial whitespace
trimstr_skip_initial:
  cmp BYTE [ecx], SPACE
  jz trimstr_initial_white
  cmp BYTE [ecx], TAB
  jz trimstr_initial_white
  jmp trimstr_copy_loop
trimstr_initial_white:
  add ecx, 1
  jmp trimstr_skip_initial

  ;; Copy until the string terminator
trimstr_copy_loop:
  cmp BYTE [ecx], 0
  mov dl, [ecx]
  mov [eax], dl
  jz trimstr_trim_end
  add ecx, 1
  add eax, 1
  jmp trimstr_copy_loop

  ;; Replace the final whitespace with terminators
trimstr_trim_end:
  cmp BYTE [eax], SPACE
  jz trimstr_final_white
  cmp BYTE [eax], TAB
  jz trimstr_final_white
  jmp trimstr_ret
trimstr_final_white:
  mov BYTE [eax], 0
  cmp eax, [esp+4]
  jz trimstr_ret
  sub eax, 1
  jmp trimstr_trim_end

trimstr_ret:
  ret


  global remove_spaces
remove_spaces:
  ;; Load registers (eax for writing, ecx for reading)
  mov eax, [esp+4]
  mov ecx, eax

  ;; Main loop
remove_spaces_loop:
  ;; Copy the byte and, if found terminator, stop
  cmp BYTE [ecx], 0
  mov dl, [ecx]
  mov [eax], dl
  jz remove_spaces_ret

  ;; Advance the read pointer; advance the write pointer only if we
  ;; did not found whitespace
  add ecx, 1
  cmp dl, SPACE
  jz remove_spaces_loop
  cmp dl, TAB
  jz remove_spaces_loop
  add eax, 1
  jmp remove_spaces_loop

remove_spaces_ret:
  ret


  global strcmp
strcmp:
  push ebx

  ;; Load registers
  mov eax, [esp+8]
  mov ecx, [esp+12]

strcmp_begin_loop:
  ;; Compare a byte
  mov bl, [eax]
  mov dl, [ecx]
  cmp bl, dl
  jz strcmp_after_cmp1

  ;; Return 1 if they differ
  ;; TODO Differentiate the less than and greater than cases
  mov eax, 1
  jmp strcmp_end

strcmp_after_cmp1:
  ;; Check for string termination
  cmp bl, 0
  jnz strcmp_after_cmp2

  ;; Return 0 if we arrived at the end without finding differences
  mov eax, 0
  jmp strcmp_end

strcmp_after_cmp2:
  ;; Increment both pointers and restart
  add eax, 1
  add ecx, 1
  jmp strcmp_begin_loop

strcmp_end:
  pop ebx
  ret


  global strcpy
strcpy:
  ;; Load registers
  mov eax, [esp+4]
  mov ecx, [esp+8]

strcpy_begin_loop:
  ;; Copy a byte
  mov dl, [ecx]
  mov [eax], dl

  ;; Return if it was the terminator
  cmp dl, 0
  jz strcpy_end

  ;; Increment both pointers and restart
  add eax, 1
  add ecx, 1
  jmp strcpy_begin_loop

strcpy_end:
  ret


  global strlen
strlen:
  ;; Load register
  mov eax, [esp+4]

strlen_begin_loop:
  ;; Check for termination
  mov cl, [eax]
  cmp cl, 0
  jz strlen_end

  ;; Increment pointer
  add eax, 1
  jmp strlen_begin_loop

strlen_end:
  ;; Return the difference between the current and initial address
  sub eax, [esp+4]
  ret


  global find_char
find_char:
  ;; Load registers
  mov eax, [esp+4]
  mov dl, [esp+8]

  ;; Main loop
find_char_loop:
  cmp [eax], dl
  jz find_char_ret
  cmp BYTE [eax], 0
  jz find_char_ret_error
  add eax, 1
  jmp find_char_loop

  ;; If we found the target character, return the difference between
  ;; the current and initial address
find_char_ret:
  sub eax, [esp+4]
  ret

  ;; If we found a terminator, return -1
find_char_ret_error:
  mov eax, 0xffffffff
  ret
