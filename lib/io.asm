;; This file is part of asmc, a bootstrapping OS with minimal seed
;; Copyright (C) 2018-2019 Giovanni Mascellani <gio@debian.org>
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

  TERM_ROW_NUM equ 25
  TERM_COL_NUM equ 80
  TERM_BASE_ADDR equ 0xb8000

term_row:
  resd 1

term_col:
  resd 1

  ;; void term_setup()
term_setup:
  ;; Compute the size of the VGA framebuffer
  mov eax, TERM_ROW_NUM
  mov edx, TERM_COL_NUM
  mul edx

  ;; Fill the VGA framebuffer with spaces char, with color light grey
  ;; 	on black
  mov ecx, TERM_BASE_ADDR
term_setup_loop:
  cmp eax, 0
  je term_setup_after_loop
  mov BYTE [ecx], SPACE
  mov BYTE [ecx+1], 0x07
  add ecx, 2
  sub eax, 1
  jmp term_setup_loop

term_setup_after_loop:
  ;; Set the cursor position
  mov eax, term_row
  mov DWORD [eax], 0
  mov eax, term_col
  mov DWORD [eax], 0

  ret


  ;; void term_set_char(int row, int col, int char)
term_set_char:
  ;; Computer the character address
  mov eax, [esp+4]
  mov edx, TERM_COL_NUM
  mul edx
  add eax, [esp+8]
  mov edx, 2
  mul edx
  add eax, TERM_BASE_ADDR

  ;; Store the new character
  mov dl, [esp+12]
  mov BYTE [eax], dl

  ret


  ;; void term_shift()
term_shift:
  push ebx

  ;; Compute the size of an entire row (stored in ecx)
  mov eax, TERM_COL_NUM
  mov edx, 2
  mul edx
  mov ecx, eax

  ;; Compute the size of all rows (stored in eax)
  mov edx, TERM_ROW_NUM
  mul edx

  ;; Store begin (ecx) and end (eax) of the buffer to copy, and the
  ;; pointer to which to copy (edx)
  add ecx, TERM_BASE_ADDR
  add eax, TERM_BASE_ADDR
  mov edx, TERM_BASE_ADDR

  ;; Copy loop
term_shift_loop:
  cmp ecx, eax
  je term_shift_after_loop
  mov bl, [ecx]
  mov [edx], bl
  add ecx, 1
  add edx, 1
  jmp term_shift_loop

term_shift_after_loop:
  mov ecx, edx
  mov eax, TERM_COL_NUM

  ;; Clear last line
term_shift_loop2:
  cmp eax, 0
  je term_shift_ret
  mov BYTE [ecx], SPACE
  mov BYTE [ecx+1], 0x07
  sub eax, 1
  add ecx, 2
  jmp term_shift_loop2

term_shift_ret:
  pop ebx
  ret


  ;; void term_put_char(int char)
term_put_char:
  ;; If the character is a newline, jump to the newline code
  mov ecx, [esp+4]
  cmp cl, NEWLINE
  je term_put_char_newline

  ;; Call term_set_char with the current position
  push ecx
  mov edx, term_col
  mov eax, [edx]
  push eax
  mov edx, term_row
  mov eax, [edx]
  push eax
  call term_set_char
  add esp, 12

  ;; Advance of one character
  mov edx, term_col
  mov eax, [edx]
  add eax, 1
  mov [edx], eax

  ;; Check for column overflow
  cmp eax, TERM_COL_NUM
  jne term_put_char_finish

  ;; Move to the beginning of next row
term_put_char_newline:
  mov edx, term_col
  mov DWORD [edx], 0
  mov edx, term_row
  mov eax, [edx]
  add eax, 1
  mov [edx], eax

  ;; Check for row overflow
  cmp eax, TERM_ROW_NUM
  jne term_put_char_finish

  ;; Reset the row position and shift all lines
  sub eax, 1
  mov [edx], eax
  call term_shift

term_put_char_finish:
  ret


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

platform_write_char_stdout:
  ;; Send stdout to terminal
  mov eax, [esp+8]
  push eax
  call term_put_char
  add esp, 4
  mov eax, [esp+8]
  push eax
  call serial_write_char
  add esp, 4
  ret

stdout_setup:
  call term_setup
  call serial_setup
  ret
