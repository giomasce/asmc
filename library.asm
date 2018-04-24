
  ITOA_BUF_LEN equ 32

section .bss

itoa_buf:
  resb ITOA_BUF_LEN

section .text

  ;; char *itoa(int x)
itoa:
  ;; Clear the buffer
  mov ecx, ITOA_BUF_LEN
  mov eax, itoa_buf

itoa_clear_loop:
  cmp ecx, 0
  je itoa_cleared
  mov BYTE [eax], SPACE
  add eax, 1
  sub ecx, 1
  jmp itoa_clear_loop

itoa_cleared:
  ;; Prepare registers
  mov eax, [esp+4]
  push esi
  mov esi, 10
  mov ecx, itoa_buf
  add ecx, ITOA_BUF_LEN
  sub ecx, 1

  ;; Store a terminator at the end
  mov BYTE [ecx], 0
  sub ecx, 1

itoa_loop:
  ;; Divide by the base
  mov edx, 0
  div esi

  ;; Output the remainder
  add edx, ZERO
  mov [ecx], dl

  ;; Check for termination
  cmp eax, 0
  je itoa_end

  ;; Move the pointer backwards
  sub ecx, 1

  jmp itoa_loop

itoa_end:
  mov eax, ecx
  pop esi
  ret
