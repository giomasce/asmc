
  extern platform_panic
  extern platform_exit
  extern platform_open_file
  extern platform_reset_file
  extern platform_read_char
  extern platform_write_char
  extern platform_log

  extern readline
  extern assemble_file

  testequ equ 100

section .bss
input_buf:
  resb 1024

section .text
global  _start

_start:
  call assemble_file
  call platform_exit

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

  global strcmp
strcmp:
  push ebx
  mov eax, [esp+8]
  mov ecx, [esp+12]
strcmp_begin_loop:
  mov bl, [eax]
  mov dl, [ecx]
  cmp bl, dl
  jz strcmp_after_cmp1
  mov eax, 1
  jmp strcmp_end
strcmp_after_cmp1:
  cmp bl, 0
  jnz strcmp_after_cmp2
  mov eax, 0
  jmp strcmp_end
strcmp_after_cmp2:
  add eax, 1
  add ecx, 1
  jmp strcmp_begin_loop
strcmp_end:
  pop ebx
  ret

  global strcpy
strcpy:
  mov eax, [esp+4]
  mov ecx, [esp+8]
strcpy_begin_loop:
  mov dl, [ecx]
  mov [eax], dl
  cmp dl, 0
  jz strcpy_end
  add eax, 1
  add ecx, 1
  jmp strcpy_begin_loop
strcpy_end:
  ret

  global strlen
strlen:
  mov eax, [esp+4]
strlen_begin_loop:
  mov cl, [eax]
  cmp cl, 0
  jz strlen_end
  add eax, 1
  jmp strlen_begin_loop
strlen_end:
  sub eax, [esp+4]
  ret
