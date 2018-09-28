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

  bits 16
  org 0x7c00

  SERIAL_PORT equ 0x3f8
  boot_disk equ 0x500

  PART1_START_LBA equ 0x7c00 + 0x1be + 8
  PART1_LENGTH equ 0x7c00 + 0x1be + 12
  PART2_START_LBA equ 0x7c00 + 0x1ce + 8
  PART2_LENGTH equ 0x7c00 + 0x1ce + 12
  PART3_START_LBA equ 0x7c00 + 0x1de + 8
  PART3_LENGTH equ 0x7c00 + 0x1de + 12
  PART4_START_LBA equ 0x7c00 + 0x1ee + 8
  PART4_LENGTH equ 0x7c00 + 0x1ee + 12

	cli
  mov ax, 0
  mov ds, ax
  mov es, ax
  mov fs, ax
  mov gs, ax
  mov ss, ax
  jmp 0:segments_set_up
segments_set_up:
	mov sp, 0x7c00

  mov [boot_disk], dl

	call serial_setup16

  mov si, str_hello
  call print_string16

  ;; Check int 0x13 extensions
  mov si, str_check_13_exts
  call print_string16
  mov ah, 0x41
  mov bx, 0x55aa
  mov dl, 0x80
  int 0x13
  jc error16

  mov si, str_boot_disk
  call print_string16
  mov al, [boot_disk]
  call print_hex_char16
  mov si, str_newline
  call print_string16

  mov si, str_loading
  call print_string16

  mov eax, [PART1_START_LBA]
  mov [lba], eax

load_stage2:
  cmp DWORD [PART1_LENGTH], 0
  je boot_stage2
  sub DWORD [PART1_LENGTH], 1

  call read_sect
  jc error16
  mov al, '.'
	call print_char16

  mov di, [buf]
  add WORD [buf], 512
  add WORD [lba], 1

  jmp load_stage2

read_sect:
  mov dl, [boot_disk]
  mov si, dap
  mov ah, 0x42
  int 0x13
  ret

boot_stage2:
	mov si, str_newline
	call print_string16
  mov si, str_booting
  call print_string16

  jmp stage2

  ;; Print character in AL
print_char16:
  call serial_write_char16
  mov ah, 0x0e
  mov bh, 0x00
  mov bl, 0x07
  int 0x10
  ret

;; Print string pointed by SI
print_string16:
  mov al, [si]
  inc si
  or al, al
  jz print_string16_ret
  call print_char16
  jmp print_string16
print_string16_ret:
  ret

print_hex_nibble16:
  and al, 0xf
  cmp al, 0xa
  jl print_hex_nibble16_decimal
  add al, 'a' - 10
  jmp print_hex_nibble16_print
print_hex_nibble16_decimal:
  add al, '0'
print_hex_nibble16_print:
  call print_char16
  ret

print_hex_char16:
  mov cl, al
  shr al, 4
  call print_hex_nibble16
  mov al, cl
  call print_hex_nibble16
  ret

platform16_panic:
error16:
	mov si, str_panic
  call print_string16
  jmp $

	;; void serial_setup()
serial_setup16:
	;; Send command as indicated in https://wiki.osdev.org/Serial_Port
	mov dx, SERIAL_PORT + 1
	mov ax, 0x00
	out dx, al

	mov dx, SERIAL_PORT + 3
	mov ax, 0x80
	out dx, al

	mov dx, SERIAL_PORT
	mov ax, 0x03
	out dx, al

	mov dx, SERIAL_PORT + 1
	mov ax, 0x00
	out dx, al

	mov dx, SERIAL_PORT + 3
	mov ax, 0x03
	out dx, al

	mov dx, SERIAL_PORT + 2
	mov ax, 0xc7
	out dx, al

	mov dx, SERIAL_PORT + 4
	mov ax, 0x0b
	out dx, al

  ;; mov ax, 11100011b
  ;; mov dx, 0
  ;; int 0x14

	ret


	;; void serial_write_char16(al)
  ;; AL is preserved
serial_write_char16:
	mov bl, al

	;; Test until the serial is available for transmit
	mov dx, SERIAL_PORT + 5
	in al, dx
  and ax, 0x20
	cmp ax, 0
	je serial_write_char16

	;; Actually write the char
	mov dx, SERIAL_PORT
  mov al, bl
	out dx, al

  ;; mov ah, 0x01
  ;; mov dx, 0
  ;; int 0x14

	ret

dap:
  db 16
  db 0
  dw 1
buf:
  dw 0x7e00
  dw 0
lba:
  dd 0
  dd 0

str_hello:
  db 'Into stage1!'
str_newline:
  db 0xa, 0xd, 0
str_panic:
  db 'PANIC!', 0xa, 0xd, 0
str_loading:
  db 'Loading stage2', 0
str_booting:
  db 'Booting stage2...', 0xa, 0xd, 0
str_boot_disk:
  db 'Boot disk: ', 0
str_check_13_exts:
  db 'Check int 0x13 exts...', 0xa, 0xd, 0

times 510 - ($ - $$) db 0
dw 0xAA55
