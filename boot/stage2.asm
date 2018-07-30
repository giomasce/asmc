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

stage2:
  mov si, str_stage2
  call print_string16

  call enable_a20

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


platform_panic:
	jmp error


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
