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

	;; Store the address of the script in ESI
	mov esi, initrd

	;; Delete comments and find the final "s"
	mov ecx, esi
find_s:
	cmp BYTE [ecx], 0x23
	je remove_comment
	cmp BYTE [ecx], 0x73
	je found_s
	add ecx, 1
	jmp find_s

remove_comment:
	mov BYTE [ecx], 0x20
	add ecx, 1
	cmp BYTE [ecx], 0x0a
	jne remove_comment
	jmp find_s

	;; Store the position after the final "s" in EDI
found_s:
	add ecx, 1
	mov edi, ecx

	;; Allocate 64kB for the stack and align to 4 bytes
	add edi, 0x10000
	and edi, 0xfffffff0
	mov esp, edi

	;; Fill 1MB of space with 0x90 (NOPs)
	mov edx, edi
	mov ecx, 0x100000
nops_fill:
	cmp ecx, 0
	je nops_filled
	sub ecx, 1
	mov BYTE [edx], 0x90
	add edx, 1
	jmp nops_fill
nops_filled:

	;; Initialize the accumulator (EAX) to 0
	mov eax, 0

	;; Use ECX to backup the original EDI value
	mov ecx, edi

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

	cmp bl, 0x43
	je code_C
	cmp bl, 0x47
	je code_G
	cmp bl, 0x4d
	je code_M
	cmp bl, 0x50
	je code_P
	cmp bl, 0x52
	je code_R
	cmp bl, 0x53
	je code_S
	cmp bl, 0x70
	je code_p
	cmp bl, 0x69
	je code_i
	cmp bl, 0x6f
	je code_o
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
failure:
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

	;; Zero accumulator
code_z:
	mov eax, 0
	jmp compile_loop

	;; Jump to position in the accumulator, failing if going backward
code_S:
	add eax, ecx
	cmp eax, edi
	jb failure
	mov edi, eax
	jmp compile_loop

	;; Stop interpreting and call the code
code_s:
	;; Check that we did not overflow the allocated 1MB
	mov edx, ecx
	add edx, 0x100000
	cmp edi, edx
	ja failure
	;; Call the compiled code
	call ecx
	;; call dump_code_and_die
	jmp loop_forever

	;; Emit push
code_P:
	mov bl, 0x68
	call emit
	mov ebx, eax
	call emit32
	jmp compile_loop

	;; Emit pop
code_p:
	mov bl, 0x58
	call emit
	jmp compile_loop

	;; Emit in
code_i:
	;; xor eax, eax; pop edx; in al, dx; push eax
	mov bl, 0x31
	call emit
	mov bl, 0xc0
	call emit
	mov bl, 0x5a
	call emit
	mov bl, 0xec
	call emit
	mov bl, 0x50
	call emit
	jmp compile_loop

	;; Emit out
code_o:
	;; pop eax; pop edx; out dx, al
	mov bl, 0x58
	call emit
	mov bl, 0x5a
	call emit
	mov bl, 0xee
	call emit
	jmp compile_loop

	;; Emit CALL
code_C:
	;; call target
	mov bl, 0xe8
	call emit
	mov ebx, eax
	add ebx, ecx
	sub ebx, edi
	sub ebx, 4
	call emit32
	jmp compile_loop

	;; Emit function prologue
code_G:
	;; push ebp; mov ebp, esp
	mov bl, 0x55
	call emit
	mov bl, 0x89
	call emit
	mov bl, 0xe5
	call emit
	jmp compile_loop

	;; Emit function epilogue
code_R:
	;; pop ebp; ret
	mov bl, 0x5d
	call emit
	mov bl, 0xc3
	call emit
	jmp compile_loop

	;; Retrieve function parameter
code_M:
	;; pop eax; push DWORD [ebp+eax*4+8]
	mov bl, 0x58
	call emit
	mov bl, 0xff
	call emit
	mov bl, 0x74
	call emit
	mov bl, 0x85
	call emit
	mov bl, 0x08
	call emit
	jmp compile_loop

emit:
	mov [edi], bl
	add edi, 1
	ret

emit32:
	mov [edi], ebx
	add edi, 4
	ret
