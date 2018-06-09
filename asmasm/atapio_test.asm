
atapio_test:
  ;; Allocate the read buffer
  push 512
  call platform_allocate
  add esp, 4
  mov ecx, atapio_buf
  mov [ecx], eax

  ;; Call IDENTIFY
  call atapio_identify

  ;; Read a sector
  push 0
  call atapio_read_sector
  add esp, 4

  ret
