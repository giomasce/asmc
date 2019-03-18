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

  WRITE_LABEL_BUF_LEN equ 128
  STACK_VARS_LEN equ 1024

  section .data

temp_var:
  db '_'
  db 0

  section .bss

label_num:
  resd 1

stack_vars_ptr:
  resd 1

block_depth:
  resd 1

stack_depth:
  resd 1

temp_depth:
  resd 1

token_given_back:
  resd 1

token_len:
  resd 1

token_buf_ptr:
  resd 1

buf2_ptr:
  resd 1

write_label_buf_ptr:
  resd 1

read_ptr:
  resd 1

read_ptr_begin:
  resd 1

read_ptr_end:
  resd 1

  section .text

  ;; Return: EAX
gen_label:
  ;; Increment by 1 gen_label and return its original value
  mov eax, [label_num]
  inc DWORD [label_num]
  ret


  ;; Input in EDX
  ;; Destroys: ECX, EDX
  ;; Return: EAX
write_label:
  ;; Write the initial dot
  mov ecx, [write_label_buf_ptr]
  mov BYTE [ecx], DOT

  ;; Move to the end of the string
  add ecx, 8

  ;; Loop over the hexadecimal digits and write them in the buffer
write_label_loop:
  mov al, dl
  call num2alphahex
  mov [ecx], al
  shr edx, 4
  dec ecx
  cmp ecx, [write_label_buf_ptr]
  jne write_label_loop

  ;; Return the buffer's address
  mov eax, [write_label_buf_ptr]
  ret


  ;; Input in EDX (variable name)
  ;; Destroys: EAX
push_var:
  push esi
  push edi

  ;; Check input length
  mov esi, edx
  call check_symbol_length

  ;; Check we are not overflowing the stack
  mov edi, [stack_depth]
  cmp edi, STACK_VARS_LEN
  jnb platform_panic

  ;; Copy the variable name in the stack
  shl edi, MAX_SYMBOL_NAME_LEN_LOG
  add edi, [stack_vars_ptr]
  mov esi, edx
  call strcpy2

  ;; Increment the stack depth
  inc DWORD [stack_depth]

  pop edi
  pop esi

  ;; If this is a temp var, increment also temp_depth
  cmp edx, temp_var
  jne push_var_non_temp
  inc DWORD [temp_depth]
  ret

  ;; If this is not a temp var, check temp_depth is zero
push_var_non_temp:
  cmp DWORD [temp_depth], 0
  jne platform_panic
  ret


  ;; Input in EAX (is temporary)
pop_var:
  ;; Check stack depth is positive and decrement it
  cmp DWORD [stack_depth], 0
  jna platform_panic
  dec DWORD [stack_depth]

  ;; If this is a temp var...
  cmp eax, 0
  jne pop_var_temp
  ret

  ;; ...check and decrement temp_depth
pop_var_temp:
  cmp DWORD [temp_depth], 0
  jna platform_panic
  dec DWORD [temp_depth]
  ret


  ;; No input
  ;; Destroys: EAX
pop_temps:
  ;; Check for termination
  cmp DWORD [temp_depth], 0
  jna pop_temps_ret

  ;; Call pop_var
  mov eax, 1
  call pop_var

  jmp pop_temps

pop_temps_ret:
  ret


  ;; Input in EDX
  ;; Destroys: ECX
  ;; Returns: EAX
find_in_stack:
  push esi
  push edi

  xor ecx, ecx
find_in_stack_loop:
  ;; Check for termination
  cmp ecx, [stack_depth]
  je find_in_stack_not_found

  ;; Compute the pointer to be checked
  mov esi, [stack_depth]
  dec esi
  sub esi, ecx
  shl esi, MAX_SYMBOL_NAME_LEN_LOG
  add esi, [stack_vars_ptr]

  ;; Call strcmp and return if it matches
  mov edi, edx
  call strcmp2
  cmp eax, 0
  je find_in_stack_found

  ;; Increment index and restart
  inc ecx
  jmp find_in_stack_loop

find_in_stack_not_found:
  mov eax, -1
  jmp find_in_stack_end

find_in_stack_found:
  mov eax, ecx
  jmp find_in_stack_end

find_in_stack_end:
  pop edi
  pop esi
  ret


  ;; Returns: EAX (either char in AL or -1 in EAX)
get_char:
  mov eax, [read_ptr]
  cmp eax, [read_ptr_end]
  je get_char_end
  mov al, [eax]
  inc DWORD [read_ptr]
  ret

get_char_end:
  mov eax, -1
  ret


  ;; Input in AL
  ;; Returns: DL
is_whitespace:
  mov dl, 1
  cmp al, SPACE
  je ret_simple
  cmp al, TAB
  je ret_simple
  cmp al, NEWLINE
  je ret_simple
  mov dl, 0
  ret


  ;; Destroys: ECX, EDX
  ;; Returns: EAX (token, which is empty at EOF)
get_token:
  ;; If the token was given back, just return it
  cmp DWORD [token_given_back], 0
  je get_token_not_gb
  mov DWORD [token_given_back], 0
  jmp get_token_ret_no_term

get_token_not_gb:
  ;; Use ECX for the buffer pointer
  mov ecx, [token_buf_ptr]

get_token_skip:
  ;; Get a char and check EOF
  call get_char
  cmp eax, -1
  je get_token_ret

  ;; Skip whitespace
  call is_whitespace
  cmp dl, 0
  jne get_token_skip

  ;; Skip comments
  cmp al, POUND
  jne get_token_skipped
get_token_skip_comment:
  call get_char
  cmp eax, -1
  je get_token_ret
  cmp al, NEWLINE
  je get_token_skip
  jmp get_token_skip_comment

get_token_skipped:
  ;; Now we have a real token; let us see what is the type
  mov dl, 0
  cmp al, QUOTE
  je get_token_string
  cmp al, APEX
  je get_token_string

  ;; Plain token, just put in chars until whitespace
get_token_plain:
  mov [ecx], al
  inc ecx
  call get_char
  cmp eax, -1
  je get_token_ret
  call is_whitespace
  cmp dl, 0
  je get_token_plain
  jmp get_token_ret

  ;; String token (DL stores whether current char is escaped)
get_token_string:
  mov [ecx], al
  inc ecx
  call get_char
  cmp eax, -1
  je platform_panic

  ;; If escaped, restart loop immediately
  cmp dl, 0
  mov dl, 0
  jne get_token_string

  ;; Last char was not a backslash and we have quote or apex: finish
  cmp al, QUOTE
  je get_token_string_end
  cmp al, APEX
  je get_token_string_end
  cmp al, BACKSLASH
  jne get_token_string
  mov dl, 1
  jmp get_token_string

get_token_string_end:
  ;; Put the closing apex or quote and return
  mov [ecx], al
  inc ecx

get_token_ret:
  ;; Put the terminator and return the buffer's address
  mov BYTE [ecx], 0
get_token_ret_no_term:
  mov eax, [token_buf_ptr]
  ret


give_back_token:
  ;; Check another token was not already given back
  cmp DWORD [token_given_back], 0
  jne platform_panic

  ;; Mark the current one as given back
  mov DWORD [token_given_back], 1
  ret


  ;; Input in DL
  ;; Returns: AL
escaped:
  xor eax, eax
  mov al, NEWLINE
  cmp dl, LITTLEN
  je escaped_ret
  mov al, TAB
  cmp dl, LITTLET
  je escaped_ret
  mov al, FEED
  cmp dl, LITTLEF
  je escaped_ret
  mov al, RETURN
  cmp dl, LITTLER
  je escaped_ret
  mov al, VERTTAB
  cmp dl, LITTLEV
  je escaped_ret
  mov al, 0
  cmp dl, ZERO
  je escaped_ret
  mov al, BACKSLASH
  cmp dl, BACKSLASH
  je escaped_ret
  mov al, APEX
  cmp dl, APEX
  je escaped_ret
  mov al, QUOTE
  cmp dl, QUOTE
  je escaped_ret

  jmp platform_panic

escaped_ret:
  ret


  ;; Input in ECX
emit_escaped_string:
  ;; Check the string beings with a quote
  cmp BYTE [ecx], QUOTE
  jne platform_panic
  inc ecx

emit_escaped_string_loop:
  ;; Check we did not find the terminator (without a closing quote)
  mov dl, [ecx]
  cmp dl, 0
  je platform_panic

  ;; If we found a quote, jump to end
  cmp dl, QUOTE
  je emit_escaped_string_end

  ;; If we found a backslash, jump to the following character and
  ;; escape it
  cmp dl, BACKSLASH
  jne emit_escaped_string_emit
  inc ecx
  mov dl, [ecx]
  call escaped
  mov dl, al

emit_escaped_string_emit:
  ;; Call emit and increment pointer
  push ecx
  mov ecx, edx
  call emit
  pop ecx
  inc ecx

  jmp emit_escaped_string_loop

emit_escaped_string_end:
  ;; Check a terminator follows and then return
  cmp BYTE [ecx+1], 0
  jne platform_panic

  ret


  ;; Input in EAX
  ;; Destroys: ECX
  ;; Returns: EAX (valid), EDX (number value)
decode_number_or_char:
  ;; The first argument does not begin with an apex, call
  ;; decode_number
  cmp BYTE [eax], APEX
  je decode_number_or_char_char
  call decode_number
  ret

decode_number_or_char_char:
  ;; Clean higher bits in EDX
  xor edx, edx

  ;; If second char is not a backslash, just return it
  cmp BYTE [eax+1], BACKSLASH
  je decode_number_or_char_backslash
  mov dl, [eax+1]

  ;; Check that the input string finishes here
  cmp BYTE [eax+2], APEX
  jne platform_panic
  cmp BYTE [eax+3], 0
  jne platform_panic

  mov eax, 1
  ret

decode_number_or_char_backslash:
  ;; Check that the input string finishes here
  cmp BYTE [eax+3], APEX
  jne platform_panic
  cmp BYTE [eax+4], 0
  jne platform_panic

  ;; Call escaped and return the result
  mov dl, [eax+2]
  call escaped
  mov dl, al

  mov eax, 1
  ret


  ;; Input in EAX
  ;; Returns: EAX
compute_rel:
  ;; Subtract current_loc and than 4
  sub eax, [current_loc]
  sub eax, 4
  ret


  ;; Input in EDX (label number)
  ;; Destroys: EAX, ECX, EDX
add_symbol_label:
  call write_label
  mov edx, -1
  mov ecx, [current_loc]
  call add_symbol_wrapper
  ret


  ;; Input in [ESP+4] (name) and [ESP+8] (want_address)
  ;; Destroys: EAX, ECX, EDX
push_expr:
  push ebp
  mov ebp, esp
  push ebx
  push esi

  ;; Try to interpret argument as number
  mov eax, [ebp+8]
  call decode_number_or_char
  cmp eax, 0
  je push_expr_stack

  ;; It is a number, check that we do not want the address
  cmp DWORD [ebp+12], 0
  jne platform_panic

  ;; Emit the code
  mov ebx, edx
  mov cl, 0x68                  ; push ??
  call emit
  mov ecx, ebx
  call emit32

  jmp push_expr_ret

push_expr_stack:
  ;; Call find_in_stack
  mov edx, [ebp+8]
  call find_in_stack
  cmp eax, -1
  je push_expr_symbol

  ;; Multiply the position by 4
  mov ebx, eax
  shl ebx, 2

  ;; It is on the stack: check if we want the address or not
  cmp DWORD [ebp+12], 0
  jne push_expr_stack_addr

  ;; We want the value, emit the code
  mov ecx, 0x24b4ff             ; push [esp+??]
  call emit24
  mov ecx, ebx
  call emit32

  jmp push_expr_ret

push_expr_stack_addr:
  ;; We want the address, emit the code
  mov ecx, 0x24848d             ; lea eax, [esp+??]
  call emit24
  mov ecx, ebx
  call emit32
  mov cl, 0x50                  ; push eax
  call emit

  jmp push_expr_ret

push_expr_symbol:
  ;; Get symbol data
  mov edx, [ebp+8]
  call find_symbol_or_panic
  mov ebx, eax

  ;; Handle (in this order) global constants, cases when we want the
  ;; address and global variables
  cmp edx, -2
  je push_expr_symbol_const
  cmp DWORD [ebp+12], 0
  jne push_expr_symbol_addr
  cmp edx, -1
  je push_expr_symbol_var

  ;; This is a real function call, save arity and emit the call
  mov esi, edx
  mov cl, 0xe8                  ; call ??
  call emit
  mov eax, ebx
  call compute_rel
  mov ecx, eax
  call emit32

  ;; Multiply the arity by 4 and emit stack unwinding
  mov ecx, 0xc481               ; add esp, ??
  call emit16
  mov ecx, esi
  shl ecx, 2
  call emit32
  mov cl, 0x50                  ; push eax
  call emit

  ;; Update stack variables
push_expr_symbol_call_loop:
  ;; Check for termination
  cmp esi, 0
  je push_expr_ret

  ;; Call pop_var
  mov eax, 1
  call pop_var

  ;; Decrement arity and reloop
  dec esi
  jmp push_expr_symbol_call_loop

push_expr_symbol_const:
  ;; Check we do not want the address
  cmp DWORD [ebp+12], 0
  jne platform_panic

  ;; But we actually emit the address, because there is where the
  ;; constant value is stored

push_expr_symbol_addr:
  ;; We want the address, emit the code
  mov cl, 0x68                  ; push ??
  call emit
  mov ecx, ebx
  call emit32

  jmp push_expr_ret

push_expr_symbol_var:
  ;; We want the value, emit the code
  mov ecx, 0x35ff               ; push [??]
  call emit16
  mov ecx, ebx
  call emit32

  jmp push_expr_ret

push_expr_ret:
  ;; Keep note of the new temporary
  mov edx, temp_var
  call push_var

  pop esi
  pop ebx
  pop ebp
  ret


  ;; Input in EAX
  ;; Destroys: EAX, ECX, EDX
push_token:
  ;; Check if it is a string
  cmp BYTE [eax], QUOTE
  je push_token_str

  ;; Check if we want the address
  xor edx, edx
  cmp BYTE [eax], AT_SIGN
  jne push_token_value
  inc eax
  inc edx

push_token_value:
  ;; Call push_expr
  push edx
  push eax
  call push_expr
  add esp, 8

  ret

push_token_str:
  push esi
  push edi
  push ebx

  mov ebx, eax

  ;; Generate a jump (in esi) and a string (in edi) label
  call gen_label
  mov esi, eax
  call gen_label
  mov edi, eax

  ;; Emit code to jump to the jump label
  mov cl, 0xe9                  ; jmp ??
  call emit
  mov edx, esi
  call write_label
  mov edx, eax
  call find_symbol_or_zero
  call compute_rel
  mov ecx, eax
  call emit32

  ;; Add a symbol for the string label
  mov edx, edi
  call add_symbol_label

  ;; Emit escaped string and a terminator
  mov ecx, ebx
  call emit_escaped_string
  mov cl, 0
  call emit

  ;; Add a symbol for the jump label
  mov edx, esi
  call add_symbol_label

  ;; Emit code to push the string label
  mov cl, 0x68                  ; push ??
  call emit
  mov edx, edi
  call write_label
  mov edx, eax
  call find_symbol_or_zero
  mov ecx, eax
  call emit32

  ;; Keep note of the new variable
  mov edx, temp_var
  call push_var

  pop ebx
  pop edi
  pop esi
  ret


  ;; Destroys: EAX, ECX, EDX
push_token_until_brace:
  ;; Get a token
  call get_token

  ;; If it is an open brace, exit loop
  mov ecx, [eax]
  and ecx, 0xffff
  cmp ecx, '{'
  je push_token_until_brace_end

  call push_token

  jmp push_token_until_brace

push_token_until_brace_end:
  ;; Given the token back
  call give_back_token

  ;; Check that temp depth is positive
  cmp DWORD [temp_depth], 0
  jna platform_panic

  ret


  ;; Destroys: EAX, ECX, EDX
parse_block:
  push ebx
  push esi
  push edi

  ;; Increment block depth
  inc DWORD [block_depth]

  ;; Save stack depth
  push DWORD [stack_depth]

  ;; Expect and discard an open curly brace token
  call get_token
  mov ecx, [eax]
  and ecx, 0xffff
  cmp ecx, '{'
  jne platform_panic

  ;; Main parsing loop
parse_block_loop:
  ;; Receive a token and save it in ebx
  call get_token
  mov ebx, eax

  ;; Ensure it is not empty (meaning EOF)
  cmp BYTE [ebx], 0
  je platform_panic

  ;; If it is a closed curly brace, then break
  mov ecx, [ebx]
  and ecx, 0xffff
  cmp ecx, '}'
  je parse_block_end

  ;; Jump to the appropriate handler

  ;; semicolon
  cmp ecx, ';'
  je parse_block_semicolon

  ;; ret
  cmp DWORD [ebx], 'ret'
  je parse_block_ret

  ;; if
  mov eax, [ebx]
  and eax, 0xffffff
  sub eax, 'if'
  je parse_block_if

  ;; while
  mov eax, [ebx]
  sub eax, 'whil'
  mov ecx, [ebx+4]
  and ecx, 0xffff
  sub ecx, 'e'
  or eax, ecx
  je parse_block_while

  ;; dollar
  cmp BYTE [ebx], DOLLAR
  je parse_block_alloc

  ;; backslash
  cmp BYTE [ebx], BACKSLASH
  je parse_block_call

  ;; Usual token push
  mov eax, ebx
  call push_token
  jmp parse_block_loop

parse_block_semicolon:
  ;; Emit code to rewind temp stack
  mov ecx, 0xc481               ; add esp, ??
  call emit16
  mov ecx, [temp_depth]
  shl ecx, 2
  call emit32
  call pop_temps

  jmp parse_block_loop

parse_block_ret:
  ;; If there are temp vars, emit code to pop one
  cmp DWORD [temp_depth], 0
  jna parse_block_ret_emit
  mov cl, 0x58                  ; pop eax
  call emit
  mov eax, 1
  call pop_var

parse_block_ret_emit:
  ;; Emit code to unwind stack and return
  mov ecx, 0xc35dec89              ; mov esp, ebp; pop ebp; ret
  call emit32

  jmp parse_block_loop

parse_block_if:
  ;; Call push_token_until_brace
  call push_token_until_brace

  ;; Generate the else label
  call gen_label
  mov ebx, eax

  ;; Emit code to pop and possibly jump to else label
  mov eax, 1
  call pop_var
  mov ecx, 0x00f88358           ; pop eax; cmp eax, 0
  call emit32
  mov ecx, 0x840f               ; je ??
  call emit16
  mov edx, ebx
  call write_label
  mov edx, eax
  call find_symbol_or_zero
  call compute_rel
  mov ecx, eax
  call emit32

  ;; Recursively parse the inner block
  call parse_block

  ;; Get another token and check if it is an else
  call get_token
  mov ecx, [eax]
  sub ecx, 'else'
  or cl, [eax+4]
  test ecx, ecx
  je parse_block_else

  ;; Not an else: add a symbol for the else label
  mov edx, ebx
  call add_symbol_label

  ;; Give the token back
  call give_back_token

  jmp parse_block_loop

parse_block_else:
  ;; There is an else: generate the fi label (load in edi)
  call gen_label
  mov edi, eax

  ;; Emit code to jump to fi
  mov cl, 0xe9                  ; jmp ??
  call emit
  mov edx, edi
  call write_label
  mov edx, eax
  call find_symbol_or_zero
  call compute_rel
  mov ecx, eax
  call emit32

  ;; Add the symbol for the else label
  mov edx, ebx
  call add_symbol_label

  ;; Recursively parse the inner block
  call parse_block

  ;; Add the symbol for the fi label
  mov edx, edi
  call add_symbol_label

  jmp parse_block_loop

parse_block_while:
  ;; Generate the restart label (in esi) and the end label (in edi)
  call gen_label
  mov esi, eax
  call gen_label
  mov edi, eax

  ;; Add a symbol for the restart label
  mov edx, esi
  call add_symbol_label

  ;; Call push_token_until_brace
  call push_token_until_brace

  ;; Emit code to pop and possibly jump to end label
  mov eax, 1
  call pop_var
  mov ecx, 0x00f88358           ; pop eax; cmp eax, 0
  call emit32
  mov ecx, 0x840f               ; je ??
  call emit16
  mov edx, edi
  call write_label
  mov edx, eax
  call find_symbol_or_zero
  call compute_rel
  mov ecx, eax
  call emit32

  ;; Recursively parse the inner block
  call parse_block

  ;; Emit code to restart the loop
  mov cl, 0xe9                  ; jmp ??
  call emit
  mov edx, esi
  call write_label
  mov edx, eax
  call find_symbol_or_zero
  call compute_rel
  mov ecx, eax
  call emit32

  ;; Add a symbol for the end label
  mov edx, edi
  call add_symbol_label

  jmp parse_block_loop

parse_block_alloc:
  ;; Call push_var
  inc ebx
  mov edx, ebx
  call push_var

  ;; Emit code
  mov ecx, 0x04ec83             ; sub esp, 4
  call emit24

  jmp parse_block_loop

parse_block_call:
  ;; Skip to following char and check it is not a terminator
  inc ebx
  cmp BYTE [ebx], 0
  je platform_panic

  ;; Call decode_number_or_symbol
  mov eax, ebx
  call decode_number_or_symbol
  mov ebx, eax

  ;; Call pop_var
  mov eax, 1
  call pop_var

  ;; Emit code to do the indirect call
  mov ecx, 0xd0ff58             ; pop eax; call eax
  call emit24

  ;; Emit code for stack cleanup
  mov ecx, 0xc481               ; add esp, ??
  call emit16
  mov ecx, ebx
  shl ecx, 2
  call emit32

  ;; Pop an appropriate number of temp vars
parse_block_call_loop:
  ;; Check for termination
  cmp ebx, 0
  je parse_block_call_end

  ;; Pop a var
  mov eax, 1
  call pop_var

  ;; Decrement counter and reloop
  dec ebx
  jmp parse_block_call_loop

parse_block_call_end:
  ;; Emit code to push the return value
  mov edx, temp_var
  call push_var
  mov cl, 0x50                  ; push eax
  call emit

  jmp parse_block_loop

parse_block_end:
  ;; Emit stack unwinding code
  mov ecx, 0xc481               ; add esp, ??
  call emit16

  ;; Sanity check: stack depth must not have decreased
  mov eax, [stack_depth]
  pop ecx
  sub eax, ecx
  jnge platform_panic

  ;; Reset stack depth to saved value and decrease block depth
  mov [stack_depth], ecx
  dec DWORD [block_depth]

  ;; Emit stack depth difference, multiplied by 4
  mov ecx, eax
  shl ecx, 2
  call emit32

  pop edi
  pop esi
  pop ebx
  ret


  ;; Input in EAX
  ;; Destroys: EBX, ECX, EDX
  ;; Returns: EAX
decode_number_or_symbol:
  ;; Try to decode as number
  mov ebx, eax
  call decode_number_or_char

  ;; If it returned true, return
  cmp eax, 0
  je decode_number_or_symbol_symbol
  mov eax, edx
  ret

decode_number_or_symbol_symbol:
  ;; Get symbol address
  mov edx, ebx
  call find_symbol_or_panic
  ret


  ;; Destroys: EAX, ECX, EDX
parse:
  push ebx

  ;; Main loop
parse_loop:
  ;; Get a token and break if it is empty
  call get_token
  mov ebx, eax
  cmp BYTE [ebx], 0
  je parse_ret

  ;; Jump to the appropriate handler

  ;; fun
  cmp DWORD [ebx], 'fun'
  je parse_fun

  ;; ifun
  mov eax, [ebx]
  sub eax, 'ifun'
  or al, [ebx+4]
  test eax, eax
  je parse_ifun

  ;; const
  mov eax, [ebx]
  sub eax, 'cons'
  mov ecx, [ebx+4]
  and ecx, 0xffff
  sub ecx, 't'
  or eax, ecx
  je parse_const

  ;; global declaration
  cmp BYTE [ebx], DOLLAR
  je parse_var

  call platform_panic

parse_fun:
  ;; Get a token and copy it in buf2 (pointed by ebx)
  mov ebx, [buf2_ptr]
  call get_token
  push eax
  push ebx
  call strcpy
  add esp, 8

  ;; Get another token and convert it to an integer
  call get_token
  call atoi

  ;; Add a symbol for the function
  mov edx, eax
  mov ecx, [current_loc]
  mov eax, ebx
  call fix_symbol_placeholder

  ;; Emit the prologue
  mov ecx, 0xe58955             ; push ebp; mov ebp, esp
  call emit24

  ;; Parse the block
  call parse_block

  ;; Emit the epilogue
  mov ecx, 0xc35d               ; pop ebp; ret
  call emit16

  jmp parse_loop

parse_ifun:
  ;; Get a token and copy it in buf2 (pointed by ebx)
  mov ebx, [buf2_ptr]
  call get_token
  push eax
  push ebx
  call strcpy
  add esp, 8

  ;; Get another token and convert it to an integer
  call get_token
  call atoi

  ;; Add a symbol placeholder for the function
  mov edx, eax
  mov eax, ebx
  call add_symbol_placeholder

  jmp parse_loop

parse_const:
  ;; Get a token and copy it in buf2 (pointed by ebx)
  mov ebx, [buf2_ptr]
  call get_token
  push eax
  push ebx
  call strcpy
  add esp, 8

  ;; Get another token and interpret it as a number or symbol
  call get_token
  call decode_number_or_symbol

  ;; Add a symbol
  mov edx, -2
  mov ecx, eax
  mov eax, [buf2_ptr]
  call add_symbol_wrapper

  jmp parse_loop

parse_var:
  ;; Increment the pointer and check the string continues
  inc ebx
  cmp BYTE [ebx], 0
  je platform_panic

  ;; Add a symbol
  mov edx, -1
  mov ecx, [current_loc]
  mov eax, ebx
  call add_symbol_wrapper

  ;; Emit a zero to allocate space for the variable
  xor ecx, ecx
  call emit32

  jmp parse_loop

parse_ret:
  pop ebx
  ret


  ;; Destroys: EAX, ECX
init_g_compiler:
  ;; Allocate stack variables list
  mov eax, STACK_VARS_LEN * MAX_SYMBOL_NAME_LEN
  call allocate
  mov [stack_vars_ptr], eax

  ;; Allocate the token buffer
  mov eax, MAX_SYMBOL_NAME_LEN
  call allocate
  mov [token_buf_ptr], eax

  ;; Allocate buf2
  mov eax, MAX_SYMBOL_NAME_LEN
  call allocate
  mov [buf2_ptr], eax

  ;; Allocate write_label_buf
  mov eax, WRITE_LABEL_BUF_LEN
  call allocate
  mov [write_label_buf_ptr], eax

  ;; Set token_given_back to false
  mov DWORD [token_given_back], 0

  ret


  ;; Destroys: EAX, ECX, EDX
compile:
  ;; Reset depths and stage
  mov DWORD [block_depth], 0
  mov DWORD [stack_depth], 0
  mov DWORD [temp_depth], 0
  mov DWORD [stage], 0

compile_stage_loop:
  ;; Check for termination
  cmp DWORD [stage], 2
  je ret_simple

  ;; Reset file to the beginning
  mov eax, [read_ptr_begin]
  mov [read_ptr], eax

  ;; Reset label_num and current_loc
  mov DWORD [label_num], 0
  mov ecx, [initial_loc]
  mov [current_loc], ecx

  ;; Call parse
  call parse

  ;; Check that depths were reset to zero
  cmp DWORD [block_depth], 0
  jne platform_panic
  cmp DWORD [stack_depth], 0
  jne platform_panic
  cmp DWORD [temp_depth], 0
  jne platform_panic

  ;; Increment stage
  add DWORD [stage], 1

  jmp compile_stage_loop

