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

  ;; This file includes snippets taken from http://wiki.osdev.org; by
  ;; https://wiki.osdev.org/OSDev_Wiki:Copyrights they are to be
  ;; considered in the public domain, or that the CC0 license applies, so
  ;; their inclusion in a GPL-3+ project should be ok.

  ATAPIO_IDENTIFY_ADDR equ 0x700

print_ata_string:
  cmp si, bx
  je print_ata_string_ret
  push bx
  mov al, [si+1]
  call print_char16
  mov al, [si]
  call print_char16
  add si, 2
  pop bx
  jmp print_ata_string

compare_ata_string:
  cmp si, bx
  je compare_ata_string_ret_true
  mov al, [si+1]
  cmp al, [di]
  jne compare_ata_string_ret_false
  mov al, [si]
  cmp al, [di+1]
  jne compare_ata_string_ret_false
  add si, 2
  add di, 2
  jmp compare_ata_string

compare_ata_string_ret_true:
  mov eax, 1
  ret

compare_ata_string_ret_false:
  mov eax, 0
  ret

print_ata_string_ret:
  ret

identify_disk:
  call atapio16_identify

  cmp eax, 0
  je identify_disk_not_found

  ;; There is a disk!
  mov si, str_found_disk
  call print_string16

  ;; Print the model number
  mov si, str_model_number
  call print_string16
  mov si, ATAPIO_IDENTIFY_ADDR+2*27
  mov bx, ATAPIO_IDENTIFY_ADDR+2*47
  call print_ata_string
  mov si, str_newline
  call print_string16

  ;; Print the serial number
  mov si, str_serial_number
  call print_string16
  mov si, ATAPIO_IDENTIFY_ADDR+2*10
  mov bx, ATAPIO_IDENTIFY_ADDR+2*20
  call print_ata_string
  mov si, str_newline
  call print_string16

  ;; Here we check that the model and serial number of the installed
	;; disks (which should be unique for each disk ever manufactured) match
	;; we an hardcoded one. In this way the content of the boot medium
	;; (which may be, for example, a USB key, which cannot be read with the
	;; simple ATA PIO driver) will be copied on the ATA hard disk only if
	;; this is the actual intended test disk.

  ;; Check the model number
  mov si, ATAPIO_IDENTIFY_ADDR+2*27
  mov bx, ATAPIO_IDENTIFY_ADDR+2*47
  mov di, str_target_model
  call compare_ata_string
  push eax

  ;; Check the serial number
  mov si, ATAPIO_IDENTIFY_ADDR+2*10
  mov bx, ATAPIO_IDENTIFY_ADDR+2*20
  mov di, str_target_serial
  call compare_ata_string

  cmp eax, 0
  pop eax
  je identify_disk_ret
  cmp eax, 0
  je identify_disk_ret

  ;; If we arrive here, that this is the target disk
  mov si, str_target_disk
  call print_string16

identify_disk_ret:
  ret

identify_disk_not_found:
  mov si, str_disk_not_found
  call print_string16
  ret

str_found_disk:
  db 'Found disk', 0xa, 0xd, 0
str_model_number:
  db 'Model number: ', 0
str_serial_number:
  db 'Serial number: ', 0
str_disk_not_found:
  db 'Disk not found', 0xa, 0xd, 0
str_identifying_disks:
  db 'Identifying disks...', 0xa, 0xd, 0
str_target_disk:
  db 'Target disk recognized!', 0xa, 0xd, 0
str_target_model:
  ;; db 'QEMU HARDDISK                           '
  db 'TOSHIBA MK6034GAX                       '
str_target_serial:
  ;; db 'QM00001             '
  db '           26B30592T'

identify_disks:
  mov DWORD [atapio16_buf], ATAPIO_IDENTIFY_ADDR

  mov si, str_identifying_disks
  call print_string16

  mov WORD [atapio16_base], 0x1f0
  mov BYTE [atapio16_master], 1
  call identify_disk

  mov WORD [atapio16_base], 0x1f0
  mov BYTE [atapio16_master], 0
  call identify_disk

  mov WORD [atapio16_base], 0x170
  mov BYTE [atapio16_master], 1
  call identify_disk

  mov WORD [atapio16_base], 0x170
  mov BYTE [atapio16_master], 0
  call identify_disk

  ret

stage2:
  mov si, str_stage2
  call print_string16

  call enable_a20

  call identify_disks

  ;; Now let us tackle protected mode
  mov si, str_enabling_protected
  call print_string16

  ;; Prepare and load a very simple GDT
  cli
  mov si, gdt_size
  mov WORD [si], gdt_end
  sub WORD [si], gdt
  sub WORD [si], 1
  mov si, gdt_offset
  mov DWORD [si], gdt
  lgdt [gdt_desc]

  ;; Enable protected mode (but not pagination)
  mov eax, cr0
  or eax, 1
  mov cr0, eax
  jmp 0x8:enter_protected

  bits 32

enter_protected:
  ;; We are finally in protected mode, we just need to reload the other segments
  mov ax, 0x10
  mov ds, ax
  mov es, ax
  mov fs, ax
  mov gs, ax
  mov ss, ax

	mov esi, str_other_side
	call print_string

  ;; Setup the ATA PIO driver
  mov WORD [atapio_base], 0x1f0
  mov BYTE [atapio_master], 1

  ;; Check the hard disk
	call atapio_identify
  cmp eax, 0
  je platform_panic

	mov esi, str_reading_payload
	call print_string

  ;; And load the actual payload
  mov DWORD [atapio_buf], 0x100000

load_payload_loop:
  mov eax, [lba]
  mov [atapio_lba], eax
  call atapio_read_sector
  cmp eax, 0
  je payload_failed

	mov esi, str_dot
	call print_string

  add DWORD [lba], 1
  add DWORD [atapio_buf], 512

  cmp DWORD [atapio_buf], 0x200000
  ja payload_loaded

  jmp load_payload_loop

payload_failed:
	mov esi, str_ex
	call print_string

	mov esi, str_newline
	call print_string

	mov esi, str_failed_payload
	call print_string

payload_loaded:
  ;; The payload is finally loaded and we can jump into it!
	mov esi, str_newline
	call print_string

	mov esi, str_chainloading
	call print_string

  jmp 0x100000

;; Print string pointed by ESI
print_string:
  mov al, [esi]
  inc esi
  or al, al
  jz print_string_ret
  call serial_write_char
  jmp print_string
print_string_ret:
  ret

platform_panic:
error:
	mov si, str_panic
  call print_string
error_loop:
  hlt
  jmp error_loop


	;; void serial_write_char(al)
serial_write_char:
	mov bl, al

	;; Test until the serial is available for transmit
	mov dx, SERIAL_PORT
	add dx, 5
	in al, dx
        and ax, 0x20
	cmp ax, 0
	je serial_write_char

	;; Actually write the char
	mov dx, SERIAL_PORT
        mov al, bl
	out dx, al

	ret


align 4

gdt_desc:
gdt_size:
dw 0
gdt_offset:
dd 0

align 4

gdt:
; Null descriptor
dd 0
dd 0
; Code descriptor
dw 0xffff
dw 0x0000
db 0x00
db 10011010b  ; Access byte
db 11001111b  ; First nibble is flags
db 0x00
; Data descriptor
dw 0xffff
dw 0x0000
db 0x00
db 10010010b  ; Access byte
db 11001111b  ; First nibble is flags
db 0x00
gdt_end:

str_stage2:
db 'Into stage2!', 0xa, 0xd, 0

str_enabling_protected:
db 'Enabling protected mode, see you on the other side!', 0xa, 0xd, 0
str_other_side:
db 'Hello there on the other side!', 0xa, 0

str_reading_payload:
db 'Loading payload', 0
str_failed_payload:
db 'Failed reading sector!', 0
str_chainloading:
db 'Chainloading payload, bye bye!', 0xa, 0
str_ex:
db 'X', 0
str_dot:
db '.', 0
