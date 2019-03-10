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

%ifdef DEBUG

  section .bss

term_row:
  resd 1

term_col:
  resd 1

  section .text

  ;; Fill the VGA framebuffer with spaces char, with color light grey
  ;; 	on black
  ;; Destroys: EAX
term_setup:
  xor eax, eax

term_setup_loop:
  mov BYTE [2*eax+TERM_BASE_ADDR], ' '
  mov BYTE [2*eax+TERM_BASE_ADDR+1], 0x07
  inc eax
  cmp eax, TERM_ROW_NUM * TERM_COL_NUM
  jne term_setup_loop

  ;; Set the cursor position
  mov DWORD [term_row], 0
  mov DWORD [term_col], 0

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
  ;; Destroys: EAX, EDX
term_shift:
  xor eax, eax

term_shift_loop:
  mov dl, [2*eax+TERM_BASE_ADDR+2*TERM_COL_NUM]
  mov [2*eax+TERM_BASE_ADDR], dl
  mov dl, [2*eax+TERM_BASE_ADDR+2*TERM_COL_NUM+1]
  mov [2*eax+TERM_BASE_ADDR+1], dl
  inc eax
  cmp eax, (TERM_ROW_NUM-1) * TERM_COL_NUM
  jne term_shift_loop

  ;; Clear last line
term_shift_loop2:
  mov BYTE [2*eax+TERM_BASE_ADDR], ' '
  mov BYTE [2*eax+TERM_BASE_ADDR+1], 0x07
  inc eax
  cmp eax, TERM_ROW_NUM * TERM_COL_NUM
  jne term_shift_loop2

term_shift_ret:
  ret


  ;; void term_put_char(int char)
  ;; Input char in CL
  ;; Destroys: EAX, EDX
term_put_char:
  ;; If the character is a newline, jump to the newline code
  cmp cl, NEWLINE
  je term_put_char_newline

  ;; Set character
  mov eax, [term_row]
  mov edx, TERM_COL_NUM
  mul edx
  add eax, [term_col]
  mov [2*eax+TERM_BASE_ADDR], cl

  ;; Advance of one character and check for column overflow
  inc DWORD [term_col]
  cmp DWORD [term_col], TERM_COL_NUM
  jne term_put_char_finish

  ;; Move to the beginning of next row and check for row overflow
term_put_char_newline:
  mov DWORD [term_col], 0
  inc DWORD [term_row]
  cmp DWORD [term_row], TERM_ROW_NUM
  jne term_put_char_finish

  ;; Reset the row position and shift all lines
  dec DWORD [term_row]
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
  ;; Input char in CL
  ;; Destroys: EAX, EDX
serial_write_char:
  ;; Test until the serial is available for transmit
  in al, SERIAL_PORT + 5
  and eax, 0x20
  je serial_write_char

  ;; Actually write the char
  mov al, cl
  mov edx, SERIAL_PORT
  out dx, al
  ret

  ;; Input char in CL
  ;; Destroys: EAX, EDX
write_console:
  ;; Send stdout to terminal
  call term_put_char
  call serial_write_char
  ret

stdout_setup:
  call term_setup
  call serial_setup
  ret

%endif
