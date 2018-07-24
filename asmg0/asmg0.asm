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


start_from_raw:
start_from_multiboot:
	mov esi, initrd
	mov eax, 0

compile_char:
	mov ebx, 0
	mov bl, [esi]

	cmp bl, 0x09
	je compile_loop
	cmp bl, 0x0a
	je compile_loop
	cmp bl, 0x0d
	je compile_loop
	cmp bl, 0x20
	je compile_loop

	cmp bl, 0x44
	je code_D
	cmp bl, 0x46
	je code_F
	cmp bl, 0x53
	je code_S
	cmp bl, 0x73
	je code_s
	cmp bl, 0x7a
	je code_z

	sub bl, 0x30
	cmp bl, 0x10
	jb code_digit

	sub bl, 0x31
	cmp bl, 0x6
	jb code_hex_digit

	;; Invalid code, failing...
	mov eax, 0xffffffff
	jmp loop_forever

compile_loop:
	add esi, 1
	jmp compile_char


	;; Process a digit into the accumulator
code_hex_digit:
	add bl, 10
code_digit:
	mov edx, 16
	mul edx
	add eax, ebx
	jmp compile_loop

	;; Set destination pointer to accumulator
code_D:
	mov edi, eax
	jmp compile_loop

	;; Emit an accumulator number of bytes 0x90 (NOPs)
code_F:
	cmp eax, 0
	je compile_loop
	mov BYTE [edi], 0x90
	sub eax, 1
	jmp code_F

	;; Add to the accumulator the address of the next "s" + 1
code_S:
	mov ecx, esi
code_S_loop:
	cmp BYTE [ecx], 0x73
	je code_S_end
	add ecx, 1
	jmp code_S_loop
code_S_end:
	add ecx, 1
	add eax, ecx
	jmp compile_loop

	;; Stop interpreting
code_s:
	jmp loop_forever

	;; Zero accumulator
code_z:
	mov eax, 0
	jmp compile_loop

	db 0x90
