;; This file is part of asmc, a bootstrapping OS with minimal seed
;; Copyright (C) 2018 Giovanni Mascellani <gio@debian.org>
;; https://gitlab.com/giomasce/asmc

;; This program is free software: you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.

;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with this program.  If not, see <https://www.gnu.org/licenses/>.

  ;; Driver written following https://wiki.osdev.org/ATA_PIO_Mode (but
  ;; all code is original)

  ATAPIO_PORT_DATA equ 0
  ATAPIO_PORT_FEATURES_ERROR equ 1
  ATAPIO_PORT_SECTOR_COUNT equ 2
  ATAPIO_PORT_LBA_LO equ 3
  ATAPIO_PORT_LBA_MID equ 4
  ATAPIO_PORT_LBA_HI equ 5
  ATAPIO_PORT_DRIVE equ 6
  ATAPIO_PORT_COMMAND equ 7

atapio_base:
  resw 1

atapio_master:
  resb 1

atapio_buf:
  resd 1

atapio_lba:
  resd 1


atapio_identify:
  ;; Send IDENTIFY
  mov dx, [atapio_base]
  add dx, ATAPIO_PORT_DRIVE
  mov al, 0xa0
  cmp BYTE [atapio_master], 0
  jne atapio_identify_cont
  mov al, 0xb0
atapio_identify_cont:
  out dx, al
  mov dx, [atapio_base]
  add dx, ATAPIO_PORT_SECTOR_COUNT
  mov al, 0
  out dx, al
  mov dx, [atapio_base]
  add dx, ATAPIO_PORT_LBA_LO
  mov al, 0
  out dx, al
  mov dx, [atapio_base]
  add dx, ATAPIO_PORT_LBA_MID
  mov al, 0
  out dx, al
  mov dx, [atapio_base]
  add dx, ATAPIO_PORT_LBA_HI
  mov al, 0
  out dx, al
  mov dx, [atapio_base]
  add dx, ATAPIO_PORT_COMMAND
  mov al, 0xec
  out dx, al

  ;; Check that drives exist and poll for the result
atapio_identify_loop:
  mov dx, [atapio_base]
  add dx, ATAPIO_PORT_COMMAND
  in al, dx
  cmp al, 0
  je atapio_identify_ret_false
  and al, 0x80
  cmp al, 0
  jne atapio_identify_loop

  ;; Check for noncompliant implementations
  mov dx, [atapio_base]
  add dx, ATAPIO_PORT_LBA_MID
  in al, dx
  cmp al, 0
  jne atapio_identify_ret_false
  mov dx, [atapio_base]
  add dx, ATAPIO_PORT_LBA_HI
  in al, dx
  cmp al, 0
  jne atapio_identify_ret_false

  ;; Wait for drive to be ready
atapio_identify_loop2:
  mov dx, [atapio_base]
  add dx, ATAPIO_PORT_COMMAND
  in al, dx
  mov cl, al
  and al, 0x1
  cmp al, 0
  jne platform_panic
  and cl, 0x8
  cmp cl, 0
  je atapio_identify_loop2

  call atapio_in_sector

  mov eax, 1
  ret

atapio_identify_ret_false:
  mov eax, 0
  ret


  ;; Read 512 bytes and store them in the buffer pointed by atapio_buf
atapio_in_sector:
  mov ecx, 0
atapio_in_sector_loop:
  cmp ecx, 512
  je atapio_in_sector_ret
  mov dx, [atapio_base]
  add dx, ATAPIO_PORT_DATA
  in ax, dx
  mov edx, atapio_buf
  mov edx, [edx]
  add edx, ecx
  mov [edx], ax
  add ecx, 2
  jmp atapio_in_sector_loop

atapio_in_sector_ret:
  ;; Discard four status reads
  mov dx, [atapio_base]
  add dx, ATAPIO_PORT_COMMAND
  in al, dx
  in al, dx
  in al, dx
  in al, dx

  ret


  ;; Write 512 bytes loading the from the buffer pointed by atapio_buf
atapio_out_sector:
  mov ecx, 0
atapio_out_sector_loop:
  cmp ecx, 512
  je atapio_out_sector_ret
  mov edx, atapio_buf
  mov edx, [edx]
  add edx, ecx
  mov ax, [edx]
  mov dx, [atapio_base]
  add dx, ATAPIO_PORT_DATA
  out dx, ax
  add ecx, 2
  jmp atapio_out_sector_loop

atapio_out_sector_ret:
  ;; Discard four status reads
  mov dx, [atapio_base]
  add dx, ATAPIO_PORT_COMMAND
  in al, dx
  in al, dx
  in al, dx
  in al, dx

  ret


atapio_poll:
  mov dx, [atapio_base]
  add dx, ATAPIO_PORT_COMMAND

  ;; Ignore the first four reads
  in al, dx
  in al, dx
  in al, dx
  in al, dx

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


atapio_wait:
  mov dx, [atapio_base]
  add dx, ATAPIO_PORT_COMMAND

  ;; Ignore the first four reads
  in al, dx
  in al, dx
  in al, dx
  in al, dx

  in al, dx
  mov cl, al

  ;; Error if ERR bit is set
  and al, 0x01
  cmp al, 0
  jne atapio_wait_ret_false

  ;; Error if DF bit is set
  mov al, cl
  and al, 0x20
  cmp al, 0
  jne atapio_wait_ret_false

  ;; Reloop if BSY is set
  mov al, cl
  and al, 0x80
  cmp al, 0
  jne atapio_wait

  mov eax, 1
  ret

atapio_wait_ret_false:
  mov eax, 0
  ret


atapio_out_lba48:
  mov dx, [atapio_base]
  add dx, ATAPIO_PORT_DRIVE
  mov ax, 0x40
  cmp BYTE [atapio_master], 0
  jne atapio_out_lba48_cont
  mov ax, 0x50
atapio_out_lba48_cont:
  out dx, al
  mov dx, [atapio_base]
  add dx, ATAPIO_PORT_SECTOR_COUNT
  mov eax, 0
  out dx, al
  mov dx, [atapio_base]
  add dx, ATAPIO_PORT_LBA_LO
  mov al, [atapio_lba+3]
  out dx, al
  mov dx, [atapio_base]
  add dx, ATAPIO_PORT_LBA_MID
  mov eax, 0
  out dx, al
  mov dx, [atapio_base]
  add dx, ATAPIO_PORT_LBA_HI
  mov eax, 0
  out dx, al
  mov dx, [atapio_base]
  add dx, ATAPIO_PORT_SECTOR_COUNT
  mov eax, 1
  out dx, al
  mov dx, [atapio_base]
  add dx, ATAPIO_PORT_LBA_LO
  mov al, [atapio_lba]
  out dx, al
  mov dx, [atapio_base]
  add dx, ATAPIO_PORT_LBA_MID
  mov al, [atapio_lba+1]
  out dx, al
  mov dx, [atapio_base]
  add dx, ATAPIO_PORT_LBA_HI
  mov al, [atapio_lba+2]
  out dx, al
  ret

atapio_read_sector:
  call atapio_out_lba48

  mov dx, [atapio_base]
  add dx, ATAPIO_PORT_COMMAND
  mov al, 0x24
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


atapio_write_sector:
  call atapio_out_lba48

  mov dx, [atapio_base]
  add dx, ATAPIO_PORT_COMMAND
  mov al, 0x34
  out dx, al

  ;; Poll and out
  call atapio_poll
  cmp eax, 0
  je atapio_write_sector_ret_false
  call atapio_out_sector

  ;; Flush cache
  mov dx, [atapio_base]
  add dx, ATAPIO_PORT_COMMAND
  mov al, 0xea
  out dx, al
  call atapio_wait

  ret

atapio_write_sector_ret_false:
  mov eax, 0
  ret
