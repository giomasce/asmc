
  AR_BUF_SIZE equ 32

ar_buf:
  resb AR_BUF_SIZE


  ;; void *walk_ar(void* x)
  ;; Read the ar file beginning at x and returns where it ends
walk_ar:
  ;; Skip the header !<arch>\n
  mov eax, [esp+4]
  add eax, 8

walk_ar_loop:
  push eax

  ;; Copy file size to the buffer
  add eax, 48
  push 10
  push eax
  push ar_buf
  call memcpy
  add esp, 12

  ;; Substitute the first space with a terminator
  push SPACE
  push ar_buf
  call find_char
  add esp, 8
  cmp eax, 0xffffffff
  je platform_panic
  add eax, ar_buf
  mov BYTE [eax], 0

  ;; Call atoi
  push ar_buf
  call atoi
  add esp, 4

  ;; Skip file header and then the file itself
  pop edx
  add edx, 60
  add edx, eax

  ;; If the file was empty, interpret as end of the archive
  cmp eax, 0
  je walk_ar_end

  ;; Realign to 2 bytes
  mov eax, edx
  sub eax, 1
  or eax, 1
  add eax, 1

  jmp walk_ar_loop

walk_ar_end:
  ret
