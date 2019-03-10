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
decode_number:
  ;; Empty string: return false
  cmp BYTE [eax], 0
  je ret_zero

  ;; Setup result
  xor edx, edx

  ;; Check hex string
  cmp WORD [eax], '0x'
  jne decode_number_dec

  ;; Check bad hex string
  add eax, 2
  mov cl, [eax]
  test cl, cl
  jz ret_zero

decode_number_hex:
  ;; Check for terminator
  xor ecx, ecx
  mov cl, [eax]
  test cl, cl
  jz ret_one

  ;; Check digit is valid
  sub cl, ZERO
  cmp cl, 10
  jb decode_number_hex_valid
  sub cl, LITTLEA - ZERO
  cmp cl, 6
  jae ret_zero
  add cl, 10

decode_number_hex_valid:
  ;; Update result and pointer
  shl edx, 4
  add edx, ecx
  inc eax
  jmp decode_number_hex

decode_number_dec:
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
  jmp decode_number_dec


  ;; Input in EAX
  ;; Destroys: ECX, EDX
  ;; Returns: EAX
atoi:
  call decode_number
  test eax, eax
  jz platform_panic
  mov eax, edx
  ret


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


  ;; Input in EDX
  ;; Destroys: EAX
  ;; Returns: ECX
get_symbol_idx:
  push esi
  push edi

  ;; Set up registers and stack
  xor ecx, ecx

get_symbol_idx_loop:
  ;; Check for termination
  cmp ecx, [symbol_num]
  je get_symbol_idx_end

  ;; Compute pointer to current symbol name
  mov esi, ecx
  shl esi, MAX_SYMBOL_NAME_LEN_LOG
  add esi, [symbol_names_ptr]

  ;; Compare with argument
  mov edi, edx
  call strcmp2

  ;; If strcmp returned 0, then we return
  cmp eax, 0
  je get_symbol_idx_end

  ;; Increment ecx and restart loop
  inc ecx
  jmp get_symbol_idx_loop

get_symbol_idx_end:
  pop edi
  pop esi
  ret


  ;; Input in EDX
  ;; Returns: EAX (found), ECX (loc), EDX (arity)
find_symbol:
  ;; Call get_symbol_idx and set return code
  call get_symbol_idx
  xor eax, eax
  cmp ecx, [symbol_num]
  je find_symbol_ret

  ;; Copy arity to EDX
  mov eax, [symbol_arities_ptr]
  mov edx, [eax+4*ecx]

  ;; Copy loc to ECX
  mov eax, [symbol_locs_ptr]
  mov ecx, [eax+4*ecx]

  ;; Return true
  mov eax, 1

find_symbol_ret:
  ret


  ;; Input in EDX
  ;; Destroys: ECX
  ;; Returns: EAX (loc), EDX (arity)
find_symbol_or_panic:
  call find_symbol
  cmp eax, 0
  je platform_panic
  mov eax, ecx
  ret


  ;; Input in EDX
  ;; Destroys: ECX, EDX
  ;; Return EAX (loc or zero)
find_symbol_or_zero:
  cmp DWORD [stage], 1
  jne ret_zero
  call find_symbol_or_panic
  ret


  ;; Input in ESI
  ;; Destroys: EAX
check_symbol_length:
  call strlen2
  cmp eax, 0
  jna platform_panic
  cmp eax, MAX_SYMBOL_NAME_LEN-1
  jnb platform_panic
  ret


  ;; Input in EAX (name), ECX (loc) and EDX (arity)
  ;; Destroys: EAX, ECX, EDX
add_symbol:
  push esi
  push edi
  push edx
  push ecx
  push eax

  ;; Check input length
  mov esi, eax
  call check_symbol_length

  ;; Call find_symbol and check the symbol does not exist yet
  pop edx
  call get_symbol_idx
  cmp ecx, [symbol_num]
  jne platform_panic

  ;; Put the current symbol number in ebx and check it is not
  ;; overflowing
  cmp ecx, SYMBOL_TABLE_LEN
  jnb platform_panic

  ;; Save the name
  mov esi, edx
  mov edi, [symbol_num]
  shl edi, MAX_SYMBOL_NAME_LEN_LOG
  add edi, [symbol_names_ptr]
  call strcpy2

  ;; Save the location for the new symbol
  mov eax, [symbol_num]
  shl eax, 2
  add eax, [symbol_locs_ptr]
  pop DWORD [eax]

  ;; Save the arity for the new symbol
  mov eax, [symbol_num]
  shl eax, 2
  add eax, [symbol_arities_ptr]
  pop DWORD [eax]

  ;; Increment and store the new symbol number
  inc DWORD [symbol_num]

  pop edi
  pop esi
  ret


  ;; Input in EAX (name), ECX (loc) and EDX (arity)
  ;; Destroys: EAX, ECX, EDX
add_symbol_wrapper:
  ;; Branch to appropriate stage
  cmp DWORD [stage], 0
  jne add_symbol_wrapper_stage1

  ;; Stage 0: call actual add_symbol
  call add_symbol

  jmp add_symbol_wrapper_ret

add_symbol_wrapper_stage1:
  ;; Save parameters
  push edx
  push ecx

  ;; Call find_symbol
  mov edx, eax
  call find_symbol

  ;; Check the symbol was found
  cmp eax, 0
  je platform_panic

  ;; Check the location matches
  pop eax
  cmp ecx, eax
  jne platform_panic

  ;; Check the arity matches
  pop eax
  cmp edx, eax
  jne platform_panic

add_symbol_wrapper_ret:
  ret


  ;; Input in EAX (symbol name), EDX (arity)
add_symbol_placeholder:
  ;; Call find_symbol
  push eax
  push edx
  mov edx, eax
  call find_symbol

  ;; Check that the symbol exists if we are not in stage 0
  cmp DWORD [stage], 0
  je add_symbol_placeholder_stage0
  cmp eax, 0
  je platform_panic

add_symbol_placeholder_stage0:
  ;; If the symbol was not found...
  cmp eax, 0
  jne add_symbol_placeholder_found

  ;; ...add it, with a fake location
  pop edx
  pop eax
  mov ecx, -1
  call add_symbol
  jmp add_symbol_placeholder_end

add_symbol_placeholder_found:
  ;; If it was found, check that arity matches
  pop eax
  cmp edx, eax
  jne platform_panic
  add esp, 4

add_symbol_placeholder_end:
  ret


  ;; Input in EAX (name), ECX (loc) and EDX (arity)
  ;; Destroys: EAX, ECX, EDX
fix_symbol_placeholder:
  ;; Call find_symbol
  push eax
  push ecx
  push edx
  mov edx, eax
  call find_symbol

  ;; Check that the symbol exists if we are not in stage 0
  cmp DWORD [stage], 0
  je fix_symbol_placeholder_stage0
  cmp eax, 0
  je platform_panic

fix_symbol_placeholder_stage0:
  ;; If the symbol was not found...
  cmp eax, 0
  jne fix_symbol_placeholder_found

  ;; ..add it
  pop edx
  pop ecx
  pop eax
  call add_symbol
  jmp add_symbol_placeholder_end

fix_symbol_placeholder_found:
  ;; If it was found, check that arity matches
  pop eax
  cmp eax, edx
  jne platform_panic

  ;; And check that loc either matches...
  pop eax
  cmp eax, ecx
  pop edx
  je fix_symbol_placeholder_end

  ;; ...or is -1 at stage 0...
  cmp ecx, -1
  jne platform_panic
  cmp DWORD [stage], 0
  jne platform_panic

  ;; ...in which case update it
  push eax
  call get_symbol_idx
  cmp ecx, [symbol_num]
  je platform_panic
  mov eax, [symbol_locs_ptr]
  pop edx
  mov [eax+4*ecx], edx

fix_symbol_placeholder_end:
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
