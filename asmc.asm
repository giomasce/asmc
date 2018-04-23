
  NEWLINE equ 0xa
  SPACE equ 0x20
  TAB equ 0x9
  ZERO equ 0x30
  NINE equ 0x39
  LITTLEA equ 0x61
  LITTLEF equ 0x66
  LITTLEX equ 0x78
  SQ_OPEN equ 0x5b
  SQ_CLOSED equ 0x5d
  PLUS equ 0x2b
  APEX equ 0x27

  INPUT_BUF_LEN equ 1024
  MAX_SYMBOL_NAME_LEN equ 128
  SYMBOL_TABLE_LEN equ 1024
  ;; SYMBOL_TABLE_SIZE = SYMBOL_TABLE_LEN * MAX_SYMBOL_NAME_LEN
  SYMBOL_TABLE_SIZE equ 131072

section .data

reg_eax:
  db 'eax'
  db 0
reg_ecx:
  db 'ecx'
  db 0
reg_edx:
  db 'edx'
  db 0
reg_ebx:
  db 'ebx'
  db 0
reg_esp:
  db 'esp'
  db 0
reg_ebp:
  db 'ebp'
  db 0
reg_esi:
  db 'esi'
  db 0
reg_edi:
  db 'edi'
  db 0

reg_al:
  db 'al'
  db 0
reg_cl:
  db 'cl'
  db 0
reg_dl:
  db 'dl'
  db 0
reg_bl:
  db 'bl'
  db 0
reg_ah:
  db 'ah'
  db 0
reg_ch:
  db 'ch'
  db 0
reg_dh:
  db 'dh'
  db 0
reg_bh:
  db 'bh'
  db 0

str_BYTE:
  db 'BYTE'
  db 0
str_DWORD:
  db 'DWORD'
  db 0

str_resb:
  db 'resb'
  db 0
str_resd:
  db 'resd'
  db 0

str_dd:
  db 'dd'
  db 0
str_db:
  db 'db'
  db 0

section .bss

input_buf:
  resb 1024

symbol_names:
  resb SYMBOL_TABLE_SIZE

symbol_loc:
  resd SYMBOL_TABLE_LEN

symbol_num:
  resd 1

current_section:
  resb MAX_SYMBOL_NAME_LEN

current_loc:
  resd 1

stage:
  resd 1

section .text

  global get_input_buf
get_input_buf:
  mov eax, input_buf
  ret

  global get_symbol_names
get_symbol_names:
  mov eax, symbol_names
  ret

  global get_symbol_loc
get_symbol_loc:
  mov eax, symbol_loc
  ret

  global get_symbol_num
get_symbol_num:
  mov eax, symbol_num
  ret

  global get_current_section
get_current_section:
  mov eax, current_section
  ret

  global get_current_loc
get_current_loc:
  mov eax, current_loc
  ret

  global get_stage
get_stage:
  mov eax, stage
  ret


  global  _start
_start:
  call assemble_file
  call platform_exit


  global assert
assert:
  cmp DWORD [esp+4], 0
  jne assert_return
  call platform_panic
assert_return:
  ret


  global readline
readline:
  push ebp
  mov ebp, esp
readline_begin_loop:
  ;; If len is zero, jump to panic
  cmp DWORD [ebp+16], 0
  je platform_panic

  ;; Call platform_read_char
  mov ecx, [ebp+8]
  push ecx
  call platform_read_char
  add esp, 4

  ;; Store the buffer address in edx
  mov edx, [ebp+12]

  ;; Handle newline and eof
  cmp eax, NEWLINE
  je readline_newline_found
  cmp eax, 0xffffffff
  je readline_eof_found

  ;; Copy a byte
  mov [edx], al

  ;; Increment the buffer and decrement the length
  add edx, 1
  mov [ebp+12], edx
  mov ecx, [ebp+16]
  sub ecx, 1
  mov [ebp+16], ecx

  jmp readline_begin_loop

  ;; On newline, store the string terminator and return 0
readline_newline_found:
  mov BYTE [edx], 0
  mov eax, 0
  jmp readline_ret

  ;; On eof, store the string terminator and return 1
readline_eof_found:
  mov BYTE [edx], 0
  mov eax, 1
  jmp readline_ret

readline_ret:
  pop ebp
  ret


  global trimstr
trimstr:
  ;; Load registers (eax for writing, ecx for reading)
  mov eax, [esp+4]
  mov ecx, eax

  ;; Skip the initial whitespace
trimstr_skip_initial:
  cmp BYTE [ecx], SPACE
  je trimstr_initial_white
  cmp BYTE [ecx], TAB
  je trimstr_initial_white
  jmp trimstr_copy_loop
trimstr_initial_white:
  add ecx, 1
  jmp trimstr_skip_initial

  ;; Copy until the string terminator
trimstr_copy_loop:
  cmp BYTE [ecx], 0
  mov dl, [ecx]
  mov [eax], dl
  je trimstr_trim_end
  add ecx, 1
  add eax, 1
  jmp trimstr_copy_loop

  ;; Replace the final whitespace with terminators
trimstr_trim_end:
  cmp BYTE [eax], SPACE
  je trimstr_final_white
  cmp BYTE [eax], TAB
  je trimstr_final_white
  jmp trimstr_ret
trimstr_final_white:
  mov BYTE [eax], 0
  cmp eax, [esp+4]
  je trimstr_ret
  sub eax, 1
  jmp trimstr_trim_end

trimstr_ret:
  ret


  global remove_spaces
remove_spaces:
  ;; Load registers (eax for writing, ecx for reading)
  mov eax, [esp+4]
  mov ecx, eax

  ;; Main loop
remove_spaces_loop:
  ;; Copy the byte and, if found terminator, stop
  cmp BYTE [ecx], 0
  mov dl, [ecx]
  mov [eax], dl
  je remove_spaces_ret

  ;; Advance the read pointer; advance the write pointer only if we
  ;; did not found whitespace
  add ecx, 1
  cmp dl, SPACE
  je remove_spaces_loop
  cmp dl, TAB
  je remove_spaces_loop
  add eax, 1
  jmp remove_spaces_loop

remove_spaces_ret:
  ret


  global strcmp
strcmp:
  push ebx

  ;; Load registers
  mov eax, [esp+8]
  mov ecx, [esp+12]

strcmp_begin_loop:
  ;; Compare a byte
  mov bl, [eax]
  mov dl, [ecx]
  cmp bl, dl
  je strcmp_after_cmp1

  ;; Return 1 if they differ
  ;; TODO Differentiate the less than and greater than cases
  mov eax, 1
  jmp strcmp_end

strcmp_after_cmp1:
  ;; Check for string termination
  cmp bl, 0
  jne strcmp_after_cmp2

  ;; Return 0 if we arrived at the end without finding differences
  mov eax, 0
  jmp strcmp_end

strcmp_after_cmp2:
  ;; Increment both pointers and restart
  add eax, 1
  add ecx, 1
  jmp strcmp_begin_loop

strcmp_end:
  pop ebx
  ret


  global isstrpref
isstrpref:
  ;; Load registers
  mov eax, [esp+4]
  mov ecx, [esp+8]

isstrpref_loop:
  ;; If the first string is finished, then return 1
  mov dl, [eax]
  cmp dl, 0
  jne isstrpref_after_cmp1
  mov eax, 1
  ret

isstrpref_after_cmp1:
  ;; If the characters do not match, return 0
  cmp dl, [ecx]
  je isstrpref_after_cmp2
  mov eax, 0
  ret

isstrpref_after_cmp2:
  ;; Increment both pointers and restart
  add eax, 1
  add ecx, 1
  jmp isstrpref_loop


  global strcpy
strcpy:
  ;; Load registers
  mov eax, [esp+4]
  mov ecx, [esp+8]

strcpy_begin_loop:
  ;; Copy a byte
  mov dl, [ecx]
  mov [eax], dl

  ;; Return if it was the terminator
  cmp dl, 0
  je strcpy_end

  ;; Increment both pointers and restart
  add eax, 1
  add ecx, 1
  jmp strcpy_begin_loop

strcpy_end:
  ret


  global strlen
strlen:
  ;; Load register
  mov eax, [esp+4]

strlen_begin_loop:
  ;; Check for termination
  mov cl, [eax]
  cmp cl, 0
  je strlen_end

  ;; Increment pointer
  add eax, 1
  jmp strlen_begin_loop

strlen_end:
  ;; Return the difference between the current and initial address
  sub eax, [esp+4]
  ret


  global find_char
find_char:
  ;; Load registers
  mov eax, [esp+4]
  mov dl, [esp+8]

  ;; Main loop
find_char_loop:
  cmp [eax], dl
  je find_char_ret
  cmp BYTE [eax], 0
  je find_char_ret_error
  add eax, 1
  jmp find_char_loop

  ;; If we found the target character, return the difference between
  ;; the current and initial address
find_char_ret:
  sub eax, [esp+4]
  ret

  ;; If we found a terminator, return -1
find_char_ret_error:
  mov eax, 0xffffffff
  ret


  global find_symbol
find_symbol:
  ;; Set up registers and stack
  push ebp
  mov ebp, esp
  mov ecx, 0

find_symbol_loop:
  ;; Check for termination
  mov eax, symbol_num
  cmp ecx, [eax]
  je find_symbol_not_found

  ;; Save ecx
  push ecx

  ;; Compute and push the second argument to strcmp
  mov edx, MAX_SYMBOL_NAME_LEN
  mov eax, ecx
  imul edx
  add eax, symbol_names
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
  je find_symbol_found

  ;; Increment ecx and check for termination
  add ecx, 1
  jmp find_symbol_loop

find_symbol_found:
  mov eax, ecx
  jmp find_symbol_ret

find_symbol_not_found:
  mov eax, SYMBOL_TABLE_LEN
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

  ;; Branch to appropriate stage
  mov edx, stage
  mov eax, [edx]
  cmp eax, 0
  je add_symbol_stage0
  cmp eax, 1
  je add_symbol_stage1
  jmp platform_panic

add_symbol_stage0:
  ;; Call find_symbol
  mov eax, [ebp+8]
  push eax
  call find_symbol
  add esp, 4

  ;; Check that the symbol does not exist yet
  cmp eax, SYMBOL_TABLE_LEN
  jne platform_panic

  ;; Put the current symbol number in ebx and check it is not
  ;; overflowing
  mov eax, symbol_num
  mov ebx, [eax]
  cmp ebx, SYMBOL_TABLE_LEN
  jnb platform_panic

  ;; Save the location for the new symbol
  mov eax, ebx
  mov ecx, 4
  imul ecx
  add eax, symbol_loc
  mov ecx, [ebp+12]
  mov [eax], ecx

  ;; Save the name for the new symbol
  mov eax, [ebp+8]
  push eax
  mov eax, ebx
  mov ecx, MAX_SYMBOL_NAME_LEN
  imul ecx
  add eax, symbol_names
  push eax
  call strcpy
  add esp, 8

  ;; Increment and store the new symbol number
  add ebx, 1
  mov eax, symbol_num
  mov [eax], ebx

  jmp add_symbol_ret

add_symbol_stage1:
  ;; Call find_symbol
  mov eax, [ebp+8]
  push eax
  call find_symbol
  add esp, 4

  ;; Check it is smaller than the symbol number
  mov ecx, symbol_num
  mov edx, [ecx]
  cmp eax, edx
  jnb platform_panic

  ;; Check the location matches with the symbol table
  mov ecx, 4
  imul ecx
  add eax, symbol_loc
  mov ecx, [ebp+12]
  cmp [eax], ecx
  jne platform_panic

  jmp add_symbol_ret

add_symbol_ret:
  pop ebx
  pop ebp
  ret


  global decode_reg32
decode_reg32:
  ;; Save and load registers
  push ebx
  mov ebx, [esp+8]
  push esi

  ;; Compare the argument with each possible register name
  mov esi, 0
  push reg_eax
  push ebx
  call strcmp
  add esp, 8
  cmp eax, 0
  je decode_reg32_ret

  mov esi, 1
  push reg_ecx
  push ebx
  call strcmp
  add esp, 8
  cmp eax, 0
  je decode_reg32_ret

  mov esi, 2
  push reg_edx
  push ebx
  call strcmp
  add esp, 8
  cmp eax, 0
  je decode_reg32_ret

  mov esi, 3
  push reg_ebx
  push ebx
  call strcmp
  add esp, 8
  cmp eax, 0
  je decode_reg32_ret

  mov esi, 4
  push reg_esp
  push ebx
  call strcmp
  add esp, 8
  cmp eax, 0
  je decode_reg32_ret

  mov esi, 5
  push reg_ebp
  push ebx
  call strcmp
  add esp, 8
  cmp eax, 0
  je decode_reg32_ret

  mov esi, 6
  push reg_esi
  push ebx
  call strcmp
  add esp, 8
  cmp eax, 0
  je decode_reg32_ret

  mov esi, 7
  push reg_edi
  push ebx
  call strcmp
  add esp, 8
  cmp eax, 0
  je decode_reg32_ret

  ;; Return -1 if none matched
  mov esi, 0xffffffff

decode_reg32_ret:
  mov eax, esi
  pop esi
  pop ebx
  ret


  global decode_reg8
decode_reg8:
  ;; Save and load registers
  push ebx
  mov ebx, [esp+8]
  push esi

  ;; Compare the argument with each possible register name
  mov esi, 0
  push reg_al
  push ebx
  call strcmp
  add esp, 8
  cmp eax, 0
  je decode_reg8_ret

  mov esi, 1
  push reg_cl
  push ebx
  call strcmp
  add esp, 8
  cmp eax, 0
  je decode_reg8_ret

  mov esi, 2
  push reg_dl
  push ebx
  call strcmp
  add esp, 8
  cmp eax, 0
  je decode_reg8_ret

  mov esi, 3
  push reg_bl
  push ebx
  call strcmp
  add esp, 8
  cmp eax, 0
  je decode_reg8_ret

  mov esi, 4
  push reg_ah
  push ebx
  call strcmp
  add esp, 8
  cmp eax, 0
  je decode_reg8_ret

  mov esi, 5
  push reg_ch
  push ebx
  call strcmp
  add esp, 8
  cmp eax, 0
  je decode_reg8_ret

  mov esi, 6
  push reg_dh
  push ebx
  call strcmp
  add esp, 8
  cmp eax, 0
  je decode_reg8_ret

  mov esi, 7
  push reg_bh
  push ebx
  call strcmp
  add esp, 8
  cmp eax, 0
  je decode_reg8_ret

  ;; Return -1 if none matched
  mov esi, 0xffffffff

decode_reg8_ret:
  mov eax, esi
  pop esi
  pop ebx
  ret


  global decode_number
decode_number:
  push ebp
  mov ebp, esp
  push ebx
  push edi
  push esi

  ;; Use eax for storing the result
  mov eax, 0

  ;; Use ebx for storing the input string
  mov ebx, [ebp+8]

  ;; Use esi to remember if we have seen at least one digit
  mov esi, 0

  ;; Determine whether we work in base 10 (edi==1) or 16 (edi==0)
  mov edi, 1
  cmp BYTE [ebx], ZERO
  jne decode_number_loop
  cmp BYTE [ebx+1], LITTLEX
  jne decode_number_loop
  mov edi, 0
  add ebx, 2

decode_number_loop:
  ;; Check if we have found the terminator
  mov cl, [ebx]
  cmp cl, 0
  je decode_number_ret

  ;; If not, then we have seen at least one digit
  mov esi, 1

  ;; Multiply the current result by 10 or 16 depending on edi
  cmp edi, 1
  jne decode_number_mult16
  mov edx, 10
  imul edx
  jmp decode_number_after_mult
decode_number_mult16:
  mov edx, 16
  imul edx

decode_number_after_mult:
  ;; If we have a decimal digit, add it to the number
  cmp cl, ZERO
  jnae decode_number_after_decimal_digit
  cmp cl, NINE
  jnbe decode_number_after_decimal_digit
  mov edx, 0
  mov dl, cl
  add eax, edx
  sub eax, ZERO
  jmp decode_number_finish_loop

decode_number_after_decimal_digit:
  ;; If we have an hexadecimal digit and we are in hexadecimal mode,
  ;; add it to the number
  cmp edi, 0
  jne decode_number_after_hex_digit
  cmp cl, LITTLEA
  jnae decode_number_after_hex_digit
  cmp cl, LITTLEF
  jnbe decode_number_after_hex_digit
  mov edx, 0
  mov dl, cl
  add eax, edx
  add eax, 10
  sub eax, LITTLEA
  jmp decode_number_finish_loop

decode_number_after_hex_digit:
  mov esi, 0
  jmp decode_number_ret

decode_number_finish_loop:
  add ebx, 1
  jmp decode_number_loop

decode_number_ret:
  mov edx, [ebp+12]
  mov [edx], eax
  mov eax, esi
  pop esi
  pop edi
  pop ebx
  pop ebp
  ret


  global decode_number_or_symbol
decode_number_or_symbol:
  push ebp
  mov ebp, esp

  ;; Call decode_number
  mov eax, [ebp+12]
  push eax
  mov eax, [ebp+8]
  push eax
  call decode_number
  add esp, 8

  ;; If decode_number succeded, return 1
  cmp eax, 1
  jne decode_number_or_symbol_after_number
  jmp decode_number_or_symbol_ret

decode_number_or_symbol_after_number:
  ;; Branch to appropriate stage (in particular, if third argument is
  ;; true assume stage 1)
  mov edx, stage
  mov eax, [edx]
  cmp eax, 1
  je decode_number_or_symbol_stage1
  cmp DWORD [ebp+16], 0
  jne decode_number_or_symbol_stage1
  cmp eax, 0
  je decode_number_or_symbol_stage0
  jmp platform_panic

decode_number_or_symbol_stage0:
  ;; Set the number to placeholder 0 and return 1
  mov eax, [ebp+12]
  mov DWORD [eax], 0
  mov eax, 1
  jmp decode_number_or_symbol_ret

decode_number_or_symbol_stage1:
  ;; Call find_symbol
  mov eax, [ebp+8]
  push eax
  call find_symbol
  add esp, 4

  ;; Check if the symbol is valid
  cmp eax, SYMBOL_TABLE_LEN
  jae decode_number_or_symbol_invalid

  ;; If it is, set the number and return 1
  mov ecx, 4
  imul ecx
  add eax, symbol_loc
  mov edx, [eax]
  mov ecx, [ebp+12]
  mov [ecx], edx
  mov eax, 1
  jmp decode_number_or_symbol_ret

decode_number_or_symbol_invalid:
  ;; If the symbol is invalid in stage 1, we have to return 0
  mov eax, 0
  jmp decode_number_or_symbol_ret

decode_number_or_symbol_ret:
  pop ebp
  ret


  global decode_operand
decode_operand:
  push ebp
  mov ebp, esp
  push ebx
  push esi

  ;; Use ebx for the input string
  mov ebx, [ebp+8]

  ;; Call remove_spaces
  push ebx
  call remove_spaces
  add esp, 4

  ;; Use cl and ch to remember if we found 8 or 32 bits code
  mov ecx, 0

  ;; Search for BYTE prefix
  push ecx
  push ebx
  push str_BYTE
  call isstrpref
  add esp, 8
  pop ecx
  cmp eax, 0
  je decode_operand_after_byte_search
  add ebx, 4
  mov cl, 1

  ;; Search for DWORD prefix
decode_operand_after_byte_search:
  push ecx
  push ebx
  push str_DWORD
  call isstrpref
  add esp, 8
  pop ecx
  cmp eax, 0
  je decode_operand_after_dword_search
  add ebx, 5
  mov ch, 1

  ;; Check that at most one prefix was found
decode_operand_after_dword_search:
  mov dl, cl
  and dl, ch
  cmp dl, 0
  jne platform_panic

  ;; Check whether the operand is direct or indirect
  cmp BYTE [ebx], SQ_OPEN
  jne decode_operand_direct

  ;; Indirect operand: mark as such and consume character
  mov edx, [ebp+12]
  mov DWORD [edx], 0
  add ebx, 1

  ;; In this branch cl and ch are not used, so we can save them in the
  ;; caller space and then recycle the register
  mov edx, [ebp+24]
  mov DWORD [edx], 0
  mov [edx], cl
  mov edx, [ebp+28]
  mov DWORD [edx], 0
  mov [edx], ch

  ;; Search for the plus
  push PLUS
  push ebx
  call find_char
  add esp, 8
  cmp eax, 0xffffffff
  jne decode_operand_have_plus

  ;; There is no plus, so the displacement is zero
  mov edx, [ebp+20]
  mov DWORD [edx], 0

  ;; Search for the closed bracket
  push SQ_CLOSED
  push ebx
  call find_char
  add esp, 8
  cmp eax, 0xffffffff
  je decode_operand_ret_false

  ;; Check that the following character is a terminator
  mov ecx, ebx
  add ecx, eax
  cmp BYTE [ecx+1], 0
  jne decode_operand_ret_false

  ;; Overwrite the closed bracket with a terminator and recognize the
  ;; register name (which must be a 32 bits register)
  mov BYTE [ecx], 0
  push ebx
  call decode_reg32
  add esp, 4

  ;; Save its value in the caller space and return appropriately
  mov edx, [ebp+16]
  mov [edx], eax
  cmp eax, 0xffffffff
  je decode_operand_ret_false
  jmp decode_operand_ret_true

decode_operand_have_plus:
  ;; Overwrite the plus with a terminator and recognize the register
  ;; name
  mov esi, ebx
  add esi, eax
  mov BYTE [esi], 0
  push ebx
  call decode_reg32
  add esp, 4

  ;; Save the register in the caller space and return 0 if it failed
  mov edx, [ebp+16]
  mov [edx], eax
  cmp eax, 0xffffffff
  je decode_operand_ret_false

  ;; Search for the closed bracket
  mov ebx, esi
  add ebx, 1
  push SQ_CLOSED
  push ebx
  call find_char
  add esp, 8
  cmp eax, 0xffffffff
  je decode_operand_ret_false

  ;; Check that the following character is a terminator
  mov ecx, ebx
  add ecx, eax
  cmp BYTE [ecx+1], 0
  jne decode_operand_ret_false

  ;; Overwrite the closed bracket with a terminator and recognized the
  ;; displacement
  mov BYTE [ecx], 0
  push 0
  mov eax, DWORD [ebp+20]
  push eax
  push ebx
  call decode_number_or_symbol
  add esp, 12
  jmp decode_operand_ret

decode_operand_direct:
  ;; Direct operand: save this fact in the caller space
  mov edx, [ebp+12]
  mov DWORD [edx], 1

  ;; No prefix should have been found in this case
  cmp ecx, 0
  jne decode_operand_ret_false

  ;; Try to recognized the operand as a 32 bits register
  push ebx
  call decode_reg32
  add esp, 4
  cmp eax, 0xffffffff
  je decode_operand_8bit

  ;; Save the register in the caller space
  mov edx, [ebp+16]
  mov [edx], eax

  ;; Save the detected size in the caller space
  mov edx, [ebp+24]
  mov DWORD [edx], 0
  mov edx, [ebp+28]
  mov DWORD [edx], 1

  jmp decode_operand_ret_true

decode_operand_8bit:
  ;; Try to recognize the operand as a 8 bits register
  push ebx
  call decode_reg8
  add esp, 4
  cmp eax, 0xffffffff
  je decode_operand_ret_false

  ;; Save the register in the caller space
  mov edx, [ebp+16]
  mov [edx], eax

  ;; Save the detected size in the caller space
  mov edx, [ebp+24]
  mov DWORD [edx], 1
  mov edx, [ebp+28]
  mov DWORD [edx], 0

  jmp decode_operand_ret_true

decode_operand_ret_true:
  mov eax, 1
  jmp decode_operand_ret

decode_operand_ret_false:
  mov eax, 0
  jmp decode_operand_ret

decode_operand_ret:
  pop esi
  pop ebx
  pop ebp
  ret


  global emit
emit:
  ;; Add 1 to the current location
  mov edx, current_loc
  add DWORD [edx], 1

  ;; If we are in stage 1, write the character
  mov edx, stage
  cmp DWORD [edx], 1
  jne emit_ret
  mov ecx, 0
  mov cl, [esp+4]
  push ecx
  push 1
  call platform_write_char
  add esp, 8

emit_ret:
  ret


  global emit32
emit32:
  ;; Emit each byte in order
  mov eax, 0
  mov al, [esp+4]
  push eax
  call emit
  add esp, 4

  mov eax, 0
  mov al, [esp+5]
  push eax
  call emit
  add esp, 4

  mov eax, 0
  mov al, [esp+6]
  push eax
  call emit
  add esp, 4

  mov eax, 0
  mov al, [esp+7]
  push eax
  call emit
  add esp, 4

  ret


  global process_bss_line
process_bss_line:
  ;; Check if the opcode is resb
  mov edx, [esp+4]
  push str_resb
  push edx
  call strcmp
  add esp, 8
  cmp eax, 0
  je process_bss_line_resb

  ;; Check is the opcode is resd
  mov edx, [esp+4]
  push str_resd
  push edx
  call strcmp
  add esp, 8
  cmp eax, 0
  je process_bss_line_resd

  mov eax, 0
  ret

process_bss_line_resb:
  ;; Save the argument before we mess up with the stack
  mov edx, [esp+8]

  ;; Push 0 to allocate a local variable and take its address
  push 0
  mov ecx, esp

  ;; Call decode_number_or_symbol
  push 1
  push ecx
  push edx
  call decode_number_or_symbol
  add esp, 12

  ;; Deallocate the temporary variable and save it in ecx
  pop ecx
  cmp eax, 0
  je platform_panic

process_bss_line_resb_loop:
  ;; Loop ecx times calling emit(0) at each loop
  cmp ecx, 0
  je process_bss_line_ret
  sub ecx, 1
  push ecx
  push 0
  call emit
  add esp, 4
  pop ecx
  jmp process_bss_line_resb_loop

  ;; Everything as above, but with emit32 instead of emit
process_bss_line_resd:
  mov edx, [esp+8]
  push 0
  mov ecx, esp
  push 1
  push ecx
  push edx
  call decode_number_or_symbol
  add esp, 12
  pop ecx
  cmp eax, 0
  je platform_panic

process_bss_line_resd_loop:
  cmp ecx, 0
  je process_bss_line_ret
  sub ecx, 1
  push ecx
  push 0
  call emit32
  add esp, 4
  pop ecx
  jmp process_bss_line_resd_loop

process_bss_line_ret:
  mov eax, 1
  ret


  global process_data_line
process_data_line:
  ;; Check if the opcode is db
  mov edx, [esp+4]
  push str_db
  push edx
  call strcmp
  add esp, 8
  cmp eax, 0
  je process_data_line_db

  ;; Check is the opcode is dd
  mov edx, [esp+4]
  push str_dd
  push edx
  call strcmp
  add esp, 8
  cmp eax, 0
  je process_data_line_dd

  mov eax, 0
  ret

process_data_line_db:
  ;; If data begin with an apex, treat it as a string
  mov edx, [esp+8]
  cmp BYTE [edx], APEX
  je process_data_line_string

  ;; If not, treat it as a single 8 bits value
  mov eax, 0
  jmp process_data_line_value

process_data_line_dd:
  ;; Assume data is a single 32 bits value
  mov edx, [esp+8]
  mov eax, 1
  jmp process_data_line_value

process_data_line_value:
  ;; Like process_bss_line_resb, but with just one emit at the end
  push eax
  push 0
  mov ecx, esp

  push 1
  push ecx
  push edx
  call decode_number_or_symbol
  add esp, 12

  pop ecx
  cmp eax, 0
  je platform_panic

  ;; We used eax to remember if data is 8 or 32 bits; call emit or
  ;; emit32 accordingly
  pop eax
  cmp eax, 0
  jne process_data_line_emit32

  push ecx
  call emit
  add esp, 4

  jmp process_data_line_ret

process_data_line_emit32:
  push ecx
  call emit32
  add esp, 4

  jmp process_data_line_ret

process_data_line_string:
  ;; Compute string length
  push edx
  push edx
  call strlen
  add esp, 4
  pop edx

  ;; Check that data has at least length 2 (the two apices)
  cmp eax, 2
  jnae platform_panic

  ;; Check that data has an apex at the end
  mov ecx, edx
  add ecx, eax
  sub ecx, 1
  cmp BYTE [ecx], APEX
  jne platform_panic

  ;; Consume the first apex and overwrite the last with a terminator
  mov BYTE [ecx], 0
  add edx, 1

  ;; Emit all the bytes
process_data_line_dd_loop:
  cmp BYTE [edx], 0
  je process_data_line_ret
  push edx
  mov ecx, 0
  mov cl, BYTE [edx]
  push ecx
  call emit
  add esp, 4
  pop edx
  add edx, 1
  jmp process_data_line_dd_loop

process_data_line_ret:
  mov eax, 1
  ret


  global emit_modrm
emit_modrm:
  ;; Check that input do not overlap when being shifted in place
  mov eax, 0x3
  and eax, [esp+4]
  cmp eax, [esp+4]
  jne platform_panic

  mov eax, 0x7
  and eax, [esp+8]
  cmp eax, [esp+8]
  jne platform_panic

  mov eax, 0x7
  and eax, [esp+12]
  cmp eax, [esp+12]
  jne platform_panic

  ;; Only support a direct register, or an indirect register + disp32
  cmp BYTE [esp+4], 0
  je platform_panic
  cmp BYTE [esp+4], 1
  je platform_panic

  ;; Assemble the first byte
  mov eax, 0
  mov al, BYTE [esp+4]
  mov edx, 8
  imul edx
  add al, BYTE [esp+8]
  mov edx, 8
  imul edx
  add al, BYTE [esp+12]

  ;; Emit the first byte
  push eax
  call emit
  add esp, 4

  ;; In the particular case of ESP used as indirect base, a SIB is
  ;; needed
  cmp BYTE [esp+4], 2
  jne emit_modrm_ret
  cmp BYTE [esp+12], 4
  jne emit_modrm_ret
  push 0x24
  call emit
  add esp, 4

emit_modrm_ret:
  ret
