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

  NEWLINE equ 0xa
  SPACE equ 0x20
  TAB equ 0x9
  FEED equ 0xc
  RETURN equ 0xd
  VERTTAB equ 0xb
  ZERO equ 0x30
  NINE equ 0x39
  LITTLEA equ 0x61
  LITTLEF equ 0x66
  LITTLEN equ 0x6e
  LITTLER equ 0x72
  LITTLET equ 0x74
  LITTLEV equ 0x76
  LITTLEX equ 0x78
  SQ_OPEN equ 0x5b
  SQ_CLOSED equ 0x5d
  PLUS equ 0x2b
  APEX equ 0x27
  COMMA equ 0x2c
  SEMICOLON equ 0x3b
  COLON equ 0x3a
  DOT equ 0x2e
  QUOTE equ 0x22
  BACKSLASH equ 0x5c
  POUND equ 0x23
  DOLLAR equ 0x24
  AMPERSAND equ 0x26
  PERCENT equ 0x25
  AT_SIGN equ 0x40

  INPUT_BUF_LEN equ 1024
  MAX_SYMBOL_NAME_LEN equ 64
  MAX_SYMBOL_NAME_LEN_LOG equ 6
  SYMBOL_TABLE_LEN equ 4096

  section .bss

symbol_names_ptr:
  resd 1

symbol_locs_ptr:
  resd 1

symbol_arities_ptr:
  resd 1

symbol_num:
  resd 1

initial_loc:
  resd 1

current_loc:
  resd 1

stage:
  resd 1

  section .data

str_symbol_already_defined:
  db 'Symbol already defined: '
  db 0
str_newline:
  db NEWLINE
  db 0

  section .text

  ;; Input number in AL
  ;; Returns: AL (hex digit corresponding to input)
num2alphahex:
  and al, 0xf
  add al, LITTLEA
  ret


  ;; Emit character in CL
  ;; Destroys: EDX
emit:
  ;; If we are in stage 1, write the character
  cmp DWORD [stage], 1
  jne emit_end
  mov edx, [current_loc]
  mov [edx], cl

emit_end:
  ;; Increment current location
  inc DWORD [current_loc]

  ret


  ;; Emit dword in ECX
  ;; Destroys: ECX, EDX
emit32:
  call emit
  shr ecx, 8
emit24:
  call emit
  shr ecx, 8
emit16:
  call emit
  shr ecx, 8
  call emit
  ret


  ;; Input in EAX
  ;; Destroys: ECX
  ;; Return: EAX (valid), EDX (number value)
decode_number2:
  ;; Empty string: return false
  cmp BYTE [eax], 0
  je ret_zero

  ;; Setup result
  xor edx, edx

  ;; Check hex string
  cmp WORD [eax], '0x'
  jne decode_number2_dec

  ;; Check bad hex string
  add eax, 2
  mov cl, [eax]
  test cl, cl
  jz ret_zero

decode_number2_hex:
  ;; Check for terminator
  xor ecx, ecx
  mov cl, [eax]
  test cl, cl
  jz ret_one

  ;; Check digit is valid
  sub cl, ZERO
  cmp cl, 10
  jb decode_number2_hex_valid
  sub cl, LITTLEA - ZERO
  cmp cl, 6
  jae ret_zero
  add cl, 10

decode_number2_hex_valid:
  ;; Update result and pointer
  shl edx, 4
  add edx, ecx
  inc eax
  jmp decode_number2_hex

decode_number2_dec:
  ;; Check for terminator
  xor ecx, ecx
  mov cl, [eax]
  test cl, cl
  jz ret_one

  ;; Check digit is valid
  sub cl, ZERO
  cmp cl, 10
  jae ret_zero

  ;; Update result and pointer
  shl edx, 1
  lea edx, [edx+4*edx]
  add edx, ecx
  inc eax
  jmp decode_number2_dec


decode_number:
  mov eax, [esp+4]
  call decode_number2
  mov ecx, [esp+8]
  mov [ecx], edx
  ret


  ;; int atoi(char*)
  global atoi
atoi:
  ;; Call decode_number, adapting the parameters
  mov eax, [esp+4]
  call decode_number2
  test eax, eax
  jz platform_panic
  mov eax, edx
  ret


  ;; void *memcpy(void *dest, const void *src, int n)
  global memcpy
memcpy:
  ;; Load registers
  mov eax, [esp+4]
  mov ecx, [esp+8]
  mov edx, [esp+12]
  push ebx

memcpy_loop:
  ;; Test for termination
  cmp edx, 0
  je memcpy_end

  ;; Copy one character
  mov bl, [ecx]
  mov [eax], bl

  ;; Decrease the counter and increase the pointers
  sub edx, 1
  add eax, 1
  add ecx, 1

  jmp memcpy_loop

memcpy_end:
  pop ebx
  ret


  global init_symbols
init_symbols:
  ;; Allocate symbol names table
  mov eax, SYMBOL_TABLE_LEN * MAX_SYMBOL_NAME_LEN
  call allocate
  mov [symbol_names_ptr], eax

  ;; Allocate symbol locations table
  mov eax, 4 * SYMBOL_TABLE_LEN
  call allocate
  mov [symbol_locs_ptr], eax

  ;; Allocate symbol arities table
  mov eax, 4 * SYMBOL_TABLE_LEN
  call allocate
  mov [symbol_arities_ptr], eax

  ;; Reset symbol_num
  mov DWORD [symbol_num], 0

  ret


  global get_symbol_idx
get_symbol_idx:
  ;; Set up registers and stack
  push ebp
  mov ebp, esp
  mov ecx, 0

get_symbol_idx_loop:
  ;; Check for termination
  cmp ecx, [symbol_num]
  je get_symbol_idx_end

  ;; Save ecx
  push ecx

  ;; Compute and push the second argument to strcmp
  mov eax, ecx
  shl eax, MAX_SYMBOL_NAME_LEN_LOG
  add eax, [symbol_names_ptr]
  push eax

  ;; Push the first argument
  mov eax, [ebp+8]
  push eax

  ;; Call strcmp, clean the stack and restore ecx
  call strcmp
  add esp, 8
  pop ecx

  ;; If strcmp returned 0, then we return
  cmp eax, 0
  je get_symbol_idx_end

  ;; Increment ecx and check for termination
  add ecx, 1
  jmp get_symbol_idx_loop

get_symbol_idx_end:
  mov eax, ecx
  pop ebp
  ret


  global find_symbol
find_symbol:
  ;; Set up registers and stack
  push ebp
  mov ebp, esp

  ;; Call get_symbol_idx
  push DWORD [ebp+8]
  call get_symbol_idx
  add esp, 4
  mov ecx, eax
  cmp ecx, [symbol_num]
  je find_symbol_not_found

  ;; If the second argument is not null, fill it with the location
  mov edx, [ebp+12]
  cmp edx, 0
  je find_symbol_arity
  mov eax, [symbol_locs_ptr]
  mov eax, [eax+4*ecx]
  mov edx, [ebp+12]
  mov [edx], eax

find_symbol_arity:
  ;; If the third argument is not null, fill it with the arity
  mov edx, [ebp+16]
  cmp edx, 0
  je find_symbol_ret_found
  mov eax, [symbol_arities_ptr]
  mov eax, [eax+4*ecx]
  mov edx, [ebp+16]
  mov [edx], eax

find_symbol_ret_found:
  mov eax, 1
  jmp find_symbol_ret

find_symbol_not_found:
  mov eax, 0
  jmp find_symbol_ret

find_symbol_ret:
  pop ebp
  ret


  global add_symbol
add_symbol:
  push ebp
  mov ebp, esp
  push ebx

  ;; Call strlen
  mov eax, [ebp+8]
  push eax
  call strlen
  add esp, 4

  ;; Check input length
  cmp eax, 0
  jna platform_panic
  cmp eax, MAX_SYMBOL_NAME_LEN
  jnb platform_panic

  ;; Call find_symbol and check the symbol does not exist yet
  push 0
  push 0
  push DWORD [ebp+8]
  call find_symbol
  add esp, 12
  cmp eax, 0
  jne add_symbol_already_defined

  ;; Put the current symbol number in ebx and check it is not
  ;; overflowing
  mov ebx, [symbol_num]
  cmp ebx, SYMBOL_TABLE_LEN
  jnb platform_panic

  ;; Save the location for the new symbol
  mov eax, ebx
  shl eax, 2
  add eax, [symbol_locs_ptr]
  mov ecx, [ebp+12]
  mov [eax], ecx

  ;; Save the arity for the new symbol
  mov eax, ebx
  shl eax, 2
  add eax, [symbol_arities_ptr]
  mov ecx, [ebp+16]
  mov [eax], ecx

  ;; Save the name for the new symbol
  mov eax, [ebp+8]
  push eax
  mov eax, ebx
  shl eax, MAX_SYMBOL_NAME_LEN_LOG
  add eax, [symbol_names_ptr]
  push eax
  call strcpy
  add esp, 8

  ;; Increment and store the new symbol number
  add ebx, 1
  mov [symbol_num], ebx

  pop ebx
  pop ebp
  ret

add_symbol_already_defined:
  ;; Log
  mov esi, str_symbol_already_defined
  call log
  mov esi, [ebp+8]
  call log
  mov esi, str_newline
  call log

  ;; Then panic
  call platform_panic


  global add_symbol_wrapper
add_symbol_wrapper:
  push ebp
  mov ebp, esp

  ;; Branch to appropriate stage
  mov edx, stage
  mov eax, [edx]
  cmp eax, 0
  je add_symbol_wrapper_stage0
  cmp eax, 1
  je add_symbol_wrapper_stage1
  jmp platform_panic

add_symbol_wrapper_stage0:
  ;; Call actual add_symbol
  push DWORD [ebp+16]
  push DWORD [ebp+12]
  push DWORD [ebp+8]
  call add_symbol
  add esp, 12

  jmp add_symbol_wrapper_ret

add_symbol_wrapper_stage1:
  ;; Call find_symbol
  push 0
  mov edx, esp
  push 0
  mov ecx, esp
  push edx
  push ecx
  push DWORD [ebp+8]
  call find_symbol
  add esp, 12
  pop edx
  pop ecx

  ;; Check the symbol was found
  cmp eax, 0
  je platform_panic

  ;; Check the location matches
  cmp edx, [ebp+12]
  jne platform_panic

  ;; Check the arity matches
  cmp ecx, [ebp+16]
  jne platform_panic

  jmp add_symbol_wrapper_ret

add_symbol_wrapper_ret:
  pop ebp
  ret


  global add_symbol_placeholder
add_symbol_placeholder:
  push ebp
  mov ebp, esp

  ;; Call find_symbol
  push 0
  mov edx, esp
  push edx
  push 0
  push DWORD [ebp+8]
  call find_symbol
  add esp, 12
  pop edx

  ;; Check that the symbol exists if we are not in stage 0
  mov ecx, stage
  cmp DWORD [ecx], 0
  je add_symbol_placeholder_after_assert
  cmp eax, 0
  je platform_panic

add_symbol_placeholder_after_assert:
  ;; If the symbol was not found...
  cmp eax, 0
  jne add_symbol_placeholder_found

  ;; ...add it, with a fake location
  push DWORD [ebp+12]
  push 0xffffffff
  push DWORD [ebp+8]
  call add_symbol
  add esp, 12
  jmp add_symbol_placeholder_end

add_symbol_placeholder_found:
  ;; If it was found, check that arity matches
  cmp [ebp+12], edx
  jne platform_panic

add_symbol_placeholder_end:
  pop ebp
  ret


  global fix_symbol_placeholder
fix_symbol_placeholder:
  push ebp
  mov ebp, esp
  push ebx

  ;; Call find_symbol
  push 0
  mov edx, esp
  push 0
  mov ecx, esp
  push edx
  push ecx
  push DWORD [ebp+8]
  call find_symbol
  add esp, 12
  pop ebx
  pop edx

  ;; Check that the symbol exists if we are not in stage 0
  mov ecx, stage
  cmp DWORD [ecx], 0
  je fix_symbol_placeholder_after_assert
  cmp eax, 0
  je platform_panic

fix_symbol_placeholder_after_assert:
  ;; If the symbol was not found...
  cmp eax, 0
  jne fix_symbol_placeholder_found

  ;; ...add it, with a fake location
  push DWORD [ebp+16]
  push DWORD [ebp+12]
  push DWORD [ebp+8]
  call add_symbol
  add esp, 12
  jmp fix_symbol_placeholder_end

fix_symbol_placeholder_found:
  ;; Check that arity matches
  cmp [ebp+16], edx
  jne platform_panic

  ;; Check that location matches, or that we are in stage 0 and
  ;; location is -1
  cmp [ebp+12], ebx
  je fix_symbol_placeholder_after_second_assert
  cmp ebx, 0xffffffff
  jne platform_panic
  mov ecx, stage
  cmp DWORD [ecx], 0
  jne platform_panic

fix_symbol_placeholder_after_second_assert:
  ;; Call get_symbol_idx
  push DWORD [ebp+8]
  call get_symbol_idx
  add esp, 4

  ;; Assert the index is valid
  mov ecx, symbol_num
  cmp [ecx], eax
  je platform_panic

  ;; Fix the location value
  shl eax, 2
  mov ecx, symbol_locs_ptr
  add eax, [ecx]
  mov edx, [ebp+12]
  mov [eax], edx

fix_symbol_placeholder_end:
  pop ebx
  pop ebp
  ret


  ;; String pointers are in ESI and EDI
  ;; Destroys: ESI, EDI
  ;; Returns: EAX
strcmp2_loop:
  cmp al, 0
  je ret_zero
  inc esi
  inc edi
strcmp2:
  mov al, [esi]
  cmp al, [edi]
  je strcmp2_loop
  jmp ret_one


  ;; String pointer in ESI
  ;; Destroys: ESI
  ;; Returns: EAX
strlen2:
  mov eax, 0
  jmp strlen2_inside
strlen2_loop:
  inc esi
  inc eax
strlen2_inside:
  cmp BYTE [esi], 0
  jne strlen2_loop
  ret


  ;; Source in ESI, destination in EDI
  ;; Destroys: ESI, EDI, EAX
strcpy2_loop:
  inc esi
  inc edi
strcpy2:
  mov al, [esi]
  mov [edi], al
  cmp al, 0
  jne strcpy2_loop
  ret


  ;; Wrapper over strcmp2
strcmp:
  push esi
  push edi
  mov esi, [esp+12]
  mov edi, [esp+16]
  call strcmp2
  pop edi
  pop esi
  ret


  ;; Wrapper over strlen2
strlen:
  push esi
  mov esi, [esp+8]
  call strlen2
  pop esi
  ret


  ;; Wrapper over strcpy2
strcpy:
  push esi
  push edi
  mov esi, [esp+16]
  mov edi, [esp+12]
  call strcpy2
  pop edi
  pop esi
  ret


  ;; Common return cases
ret_zero:
  xor eax, eax
ret_simple:
  ret

ret_one:
  xor eax, eax
  inc eax
  ret
