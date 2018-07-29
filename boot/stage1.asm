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
  atapio_buf16 equ 0x500
  lba equ 0x504
  boot_disk equ 0x508
  dap equ 0x50c

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
  call print_hex_char
  mov si, str_newline
  call print_string16

  mov si, str_loading
  call print_string16

  mov DWORD [atapio_buf16], 0x7e00
  mov DWORD [lba], 1

load_stage2:
  mov dl, [boot_disk]
  mov bx, [atapio_buf16]
  mov ax, [lba]
  call read_sector
  jc error16
	mov si, str_dot
	call print_string16

  mov di, [atapio_buf16]
  add WORD [atapio_buf16], 512
  add WORD [lba], 1

  ;; The constant 0x706f7473 ("stop" in little endian) is used
  ;; to mark when to stop loading
  cmp DWORD [di], 0x706f7473
  je boot_stage2
  jmp load_stage2

boot_stage2:
	mov si, str_newline
	call print_string16
  mov si, str_booting
  call print_string16

  jmp stage2

  ;; Drive number in DL, sector number in AX, destination in ES:BX
  ;; Set CF on error
read_sector:
  mov byte [dap], 16
  mov byte [dap+1], 0
  mov word [dap+2], 1
  mov word [dap+4], bx
  mov word [dap+6], es
  mov word [dap+8], ax
  mov word [dap+10], 0
  mov dword [dap+12], 0
  mov si, dap
  mov ah, 0x42
  int 0x13
  ret

  ;; Print character in AL
print_char16:
  call serial_write_char16
  mov ah, 0x0e
  mov bx, 0x00
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

print_hex_nibble:
  and al, 0xf
  cmp al, 0xa
  jl print_hex_nibble_decimal
  add al, 'a' - 10
  jmp print_hex_nibble_print
print_hex_nibble_decimal:
  add al, '0'
print_hex_nibble_print:
  call print_char16
  ret

print_hex_char:
  mov cl, al
  shr al, 4
  call print_hex_nibble
  mov al, cl
  call print_hex_nibble
  ret

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

	ret


str_hello:
  db 'Into stage1!', 0xa, 0xd, 0
str_panic:
  db 'PANIC!', 0xa, 0xd, 0
str_loading:
  db 'Loading', 0
str_dot:
  db '.', 0
str_newline:
  db 0xa, 0xd, 0
str_booting:
  db 'Booting stage2...', 0xa, 0xd, 0
str_boot_disk:
  db 'Boot disk: ', 0
str_check_13_exts:
  db 'Check int 0x13 exts...', 0xa, 0xd, 0

times 510 - ($ - $$) db 0
dw 0xAA55
