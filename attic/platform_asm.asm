
global do_syscall
do_syscall:
  push ebp
  mov ebp, esp
  push ebx

  mov edx, [ebp+20]
  mov ecx, [ebp+16]
  mov ebx, [ebp+12]
  mov eax, [ebp+8]
  int 0x80

  pop ebx
  pop ebp
  ret
