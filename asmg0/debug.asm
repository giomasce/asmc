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


dump_nibble:
	cmp al, 10
	jb dump_nibble_dec
	sub al, 10
	add al, 0x61
	push eax
	call serial_write_char
	add esp, 4
	ret
dump_nibble_dec:
	add al, 0x30
	push eax
	call serial_write_char
	add esp, 4
	ret

dump_byte:
	mov ebx, eax
	mov edx, 0
	mov ecx, 16
	div ecx
	and eax, 0xf
	call dump_nibble
	mov eax, ebx
	and eax, 0xf
	call dump_nibble
	mov eax, 0x20
	push eax
	call serial_write_char
	add esp, 4
	ret

dump_code_and_die:
	call serial_setup
	mov esi, ecx
	mov edi, 0x100
dump_code_and_die_loop:
	cmp edi, 0
	je dump_code_and_die_end
	mov eax, 0
	mov al, [esi]
	call dump_byte
	add esi, 1
	sub edi, 1
	jmp dump_code_and_die_loop
dump_code_and_die_end:
	push 0xa
	call serial_write_char
	add esp, 4
	mov eax, 0
	jmp loop_forever


  SERIAL_PORT equ 0x3f8

	;; void serial_setup()
serial_setup:
	;; Send command as indicated in https://wiki.osdev.org/Serial_Port
	mov edx, SERIAL_PORT
	add edx, 1
	mov eax, 0x00
	out dx, al

	mov edx, SERIAL_PORT
	add edx, 3
	mov eax, 0x80
	out dx, al

	mov edx, SERIAL_PORT
	add edx, 0
	mov eax, 0x03
	out dx, al

	mov edx, SERIAL_PORT
	add edx, 1
	mov eax, 0x00
	out dx, al

	mov edx, SERIAL_PORT
	add edx, 3
	mov eax, 0x03
	out dx, al

	mov edx, SERIAL_PORT
	add edx, 2
	mov eax, 0xc7
	out dx, al

	mov edx, SERIAL_PORT
	add edx, 4
	mov eax, 0x0b
	out dx, al

	ret


	;; void serial_write_char(char c)
serial_write_char:
	;; Test until the serial is available for transmit
	mov edx, SERIAL_PORT
	add edx, 5
	in al, dx
        and eax, 0x20
	cmp eax, 0
	je serial_write_char

	;; Actually write the char
	mov edx, SERIAL_PORT
        mov eax, [esp+4]
	out dx, al

 	ret
