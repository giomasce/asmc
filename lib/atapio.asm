
  ;; Driver written following https://wiki.osdev.org/ATA_PIO_Mode (but
  ;; all code is original)

  ATAPIO_DATA equ 0x1f0
  ATAPIO_FEATURES_ERROR equ 0x1f1
  ATAPIO_SECTOR_COUNT equ 0x1f2
  ATAPIO_LBA_LO equ 0x1f3
  ATAPIO_LBA_MID equ 0x1f4
  ATAPIO_LBA_HI equ 0x1f5
  ATAPIO_DRIVE equ 0x1f6
  ATAPIO_COMMAND equ 0x1f7
  ATAPIO_DCR equ 0x3f6


atapio_buf:
  resd 1


atapio_identify:
  ;; Send IDENTIFY
  mov edx, ATAPIO_DRIVE
  mov eax, 0xa0
  out dx, al
  mov edx, ATAPIO_SECTOR_COUNT
  mov eax, 0
  out dx, al
  mov edx, ATAPIO_LBA_LO
  mov eax, 0
  out dx, al
  mov edx, ATAPIO_LBA_MID
  mov eax, 0
  out dx, al
  mov edx, ATAPIO_LBA_HI
  mov eax, 0
  out dx, al
  mov edx, ATAPIO_COMMAND
  mov eax, 0xec
  out dx, al

  ;; Check that drives exist and poll for the result
atapio_identify_loop:
  mov edx, ATAPIO_COMMAND
  in al, dx
  cmp al, 0
  je platform_panic
  and al, 0x80
  cmp al, 0
  jne atapio_identify_loop

  ;; Check for noncompliant implementations
  mov edx, ATAPIO_LBA_MID
  in al, dx
  cmp al, 0
  jne platform_panic
  mov edx, ATAPIO_LBA_HI
  in al, dx
  cmp al, 0
  jne platform_panic

  ;; Wait for drive to be ready
atapio_identify_loop2:
  mov edx, ATAPIO_COMMAND
  in al, dx
  mov cl, al
  and al, 0x1
  cmp al, 0
  jne platform_panic
  and cl, 0x8
  cmp cl, 0
  je atapio_identify_loop2

  call atapio_in_sector

  ret


  ;; Read 512 bytes and store them in atapio_buf
atapio_in_sector:
  mov ecx, 0
atapio_in_sector_loop:
  cmp ecx, 512
  je atapio_in_sector_ret
  mov edx, ATAPIO_DATA
  in ax, dx
  mov edx, atapio_buf
  mov edx, [edx]
  add edx, ecx
  mov [edx], al
  mov [edx+1], ah
  add ecx, 2
  jmp atapio_in_sector_loop

atapio_in_sector_ret:
  ret


  ;; bool atapio_poll()
atapio_poll:
  mov edx, ATAPIO_COMMAND
  in al, dx
  mov cl, al

  ;; Error if ERR bit is set
  and al, 0x01
  cmp al, 0
  jne atapio_poll_ret_false

  ;; Error if DF bit is set
  mov al, cl
  and al, 0x20
  cmp al, 0
  jne atapio_poll_ret_false

  ;; Reloop if BSY is set
  mov al, cl
  and al, 0x80
  cmp al, 0
  jne atapio_poll

  ;; Reloop if DRQ is not set
  mov al, cl
  and al, 0x08
  cmp al, 0
  je atapio_poll

  mov eax, 1
  ret

atapio_poll_ret_false:
  mov eax, 0
  ret


  ;; bool atapio_read_sector(int lba)
atapio_read_sector:
  ;; Send READ SECTORS EXT
  mov edx, ATAPIO_DRIVE
  mov eax, 0x40
  out dx, al
  mov edx, ATAPIO_SECTOR_COUNT
  mov eax, 0
  out dx, al
  mov edx, ATAPIO_LBA_LO
  mov al, [esp+7]
  out dx, al
  mov edx, ATAPIO_LBA_MID
  mov eax, 0
  out dx, al
  mov edx, ATAPIO_LBA_HI
  mov eax, 0
  out dx, al
  mov edx, ATAPIO_SECTOR_COUNT
  mov eax, 1
  out dx, al
  mov edx, ATAPIO_LBA_LO
  mov al, [esp+4]
  out dx, al
  mov edx, ATAPIO_LBA_MID
  mov al, [esp+5]
  out dx, al
  mov edx, ATAPIO_LBA_HI
  mov al, [esp+6]
  out dx, al
  mov edx, ATAPIO_COMMAND
  mov eax, 0x24
  out dx, al

  ;; Poll and in
  call atapio_poll
  cmp eax, 0
  je atapio_read_sector_ret_false
  call atapio_in_sector
  mov eax, 1
  ret

atapio_read_sector_ret_false:
  mov eax, 0
  ret



;atapio_test:
  ;; Allocate the read buffer
;  push 512
;  call platform_allocate
;  add esp, 4
;  mov ecx, atapio_buf
;  mov [ecx], eax

  ;; Call IDENTIFY
;  call atapio_identify

  ;; Read a sector
;  push 0
;  call atapio_read_sector
;  add esp, 4

;  ret
