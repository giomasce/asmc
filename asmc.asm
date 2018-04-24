
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
  COMMA equ 0x2c

  OP_PUSH equ 0
  OP_POP equ 1
  OP_ADD equ 2
  OP_SUB equ 3
  OP_MOV equ 4
  OP_CMP equ 5
  OP_AND equ 6
  OP_OR equ 7
  OP_JMP equ 8
  OP_CALL equ 9
  OP_JE equ 10
  OP_JNE equ 11
  OP_JA equ 12
  OP_JNA equ 13
  OP_JAE equ 14
  OP_JNAE equ 15
  OP_JB equ 16
  OP_JNB equ 17
  OP_JBE equ 18
  OP_JNBE equ 19
  OP_JG equ 20
  OP_JNG equ 21
  OP_JGE equ 22
  OP_JNGE equ 23
  OP_JL equ 24
  OP_JNL equ 25
  OP_JLE equ 26
  OP_JNLE equ 27
  OP_MUL equ 28
  OP_IMUL equ 29
  OP_INT equ 30
  OP_RET equ 31

  INPUT_BUF_LEN equ 1024
  MAX_SYMBOL_NAME_LEN equ 128
  SYMBOL_TABLE_LEN equ 1024
  ;; SYMBOL_TABLE_SIZE = SYMBOL_TABLE_LEN * MAX_SYMBOL_NAME_LEN
  SYMBOL_TABLE_SIZE equ 131072

section .data

opcode_names:
  db 'push'
  db 0
  db 'pop'
  db 0
  db 'add'
  db 0
  db 'sub'
  db 0
  db 'mov'
  db 0
  db 'cmp'
  db 0
  db 'and'
  db 0
  db 'or'
  db 0
  db 'jmp'
  db 0
  db 'call'
  db 0
  db 'je'
  db 0
  db 'jne'
  db 0
  db 'ja'
  db 0
  db 'jna'
  db 0
  db 'jae'
  db 0
  db 'jnae'
  db 0
  db 'jb'
  db 0
  db 'jnb'
  db 0
  db 'jbe'
  db 0
  db 'jnbe'
  db 0
  db 'jg'
  db 0
  db 'jng'
  db 0
  db 'jge'
  db 0
  db 'jnge'
  db 0
  db 'jl'
  db 0
  db 'jnl'
  db 0
  db 'jle'
  db 0
  db 'jnle'
  db 0
  db 'mul'
  db 0
  db 'imul'
  db 0
  db 'int'
  db 0
  db 'ret'
  db 0
  db 0

opcode_funcs:
  dd process_push_like   ; OP_PUSH
  dd process_push_like   ; OP_POP
  dd process_add_like    ; OP_ADD
  dd process_add_like    ; OP_SUB
  dd process_add_like    ; OP_MOV
  dd process_add_like    ; OP_CMP
  dd process_add_like    ; OP_AND
  dd process_add_like    ; OP_OR
  dd process_jmp_like    ; OP_JMP
  dd process_jmp_like    ; OP_CALL
  dd process_jmp_like    ; OP_JE
  dd process_jmp_like    ; OP_JNE
  dd process_jmp_like    ; OP_JA
  dd process_jmp_like    ; OP_JNA
  dd process_jmp_like    ; OP_JAE
  dd process_jmp_like    ; OP_JNAE
  dd process_jmp_like    ; OP_JB
  dd process_jmp_like    ; OP_JNB
  dd process_jmp_like    ; OP_JBE
  dd process_jmp_like    ; OP_JNBE
  dd process_jmp_like    ; OP_JG
  dd process_jmp_like    ; OP_JNG
  dd process_jmp_like    ; OP_JGE
  dd process_jmp_like    ; OP_JNGE
  dd process_jmp_like    ; OP_JL
  dd process_jmp_like    ; OP_JNL
  dd process_jmp_like    ; OP_JLE
  dd process_jmp_like    ; OP_JNLE
  dd process_jmp_like    ; OP_MUL
  dd process_jmp_like    ; OP_IMUL
  dd process_int         ; OP_INT
  dd process_ret         ; OP_RET

rm32_opcode:
  dd 0x06ff  ; OP_PUSH
  dd 0x008f  ; OP_POP
  dd 0xf0    ; OP_ADD
  dd 0xf0    ; OP_SUB
  dd 0xf0    ; OP_MOV
  dd 0xf0    ; OP_CMP
  dd 0xf0    ; OP_AND
  dd 0xf0    ; OP_OR
  dd 0x04ff  ; OP_JMP
  dd 0x02ff  ; OP_CALL
  dd 0xf0    ; OP_JE
  dd 0xf0    ; OP_JNE
  dd 0xf0    ; OP_JA
  dd 0xf0    ; OP_JNA
  dd 0xf0    ; OP_JAE
  dd 0xf0    ; OP_JNAE
  dd 0xf0    ; OP_JB
  dd 0xf0    ; OP_JNB
  dd 0xf0    ; OP_JBE
  dd 0xf0    ; OP_JNBE
  dd 0xf0    ; OP_JG
  dd 0xf0    ; OP_JNG
  dd 0xf0    ; OP_JGE
  dd 0xf0    ; OP_JNGE
  dd 0xf0    ; OP_JL
  dd 0xf0    ; OP_JNL
  dd 0xf0    ; OP_JLE
  dd 0xf0    ; OP_JNLE
  dd 0x04f7  ; OP_MUL
  dd 0x05f7  ; OP_IMUL
  dd 0xf0    ; OP_INT
  dd 0xf0    ; OP_RET

imm32_opcode:
  dd 0xf0    ; OP_PUSH
  dd 0xf0    ; OP_POP
  dd 0xf0    ; OP_ADD
  dd 0xf0    ; OP_SUB
  dd 0xf0    ; OP_MOV
  dd 0xf0    ; OP_CMP
  dd 0xf0    ; OP_AND
  dd 0xf0    ; OP_OR
  dd 0xe9    ; OP_JMP
  dd 0xe8    ; OP_CALL
  dd 0x1840f ; OP_JE
  dd 0x1850f ; OP_JNE
  dd 0x1870f ; OP_JA
  dd 0x1860f ; OP_JNA
  dd 0x1830f ; OP_JAE
  dd 0x1820f ; OP_JNAE
  dd 0x1820f ; OP_JB
  dd 0x1830f ; OP_JNB
  dd 0x1860f ; OP_JBE
  dd 0x1870f ; OP_JNBE
  dd 0x18f0f ; OP_JG
  dd 0x18e0f ; OP_JNG
  dd 0x18d0f ; OP_JGE
  dd 0x18c0f ; OP_JNGE
  dd 0x18c0f ; OP_JL
  dd 0x18d0f ; OP_JNL
  dd 0x18e0f ; OP_JLE
  dd 0x18f0f ; OP_JNLE
  dd 0xf0    ; OP_MUL
  dd 0xf0    ; OP_IMUL
  dd 0xf0    ; OP_INT
  dd 0xf0    ; OP_RET

r8rm8_opcode:
  dd 0xf0    ; OP_PUSH
  dd 0xf0    ; OP_POP
  dd 0x02    ; OP_ADD
  dd 0x2a    ; OP_SUB
  dd 0x8a    ; OP_MOV
  dd 0x3a    ; OP_CMP
  dd 0x22    ; OP_AND
  dd 0x0a    ; OP_OR
  dd 0xf0    ; OP_JMP
  dd 0xf0    ; OP_CALL
  dd 0xf0    ; OP_JE
  dd 0xf0    ; OP_JNE
  dd 0xf0    ; OP_JA
  dd 0xf0    ; OP_JNA
  dd 0xf0    ; OP_JAE
  dd 0xf0    ; OP_JNAE
  dd 0xf0    ; OP_JB
  dd 0xf0    ; OP_JNB
  dd 0xf0    ; OP_JBE
  dd 0xf0    ; OP_JNBE
  dd 0xf0    ; OP_JG
  dd 0xf0    ; OP_JNG
  dd 0xf0    ; OP_JGE
  dd 0xf0    ; OP_JNGE
  dd 0xf0    ; OP_JL
  dd 0xf0    ; OP_JNL
  dd 0xf0    ; OP_JLE
  dd 0xf0    ; OP_JNLE
  dd 0xf0    ; OP_MUL
  dd 0xf0    ; OP_IMUL
  dd 0xf0    ; OP_INT
  dd 0xf0    ; OP_RET

r32rm32_opcode:
  dd 0xf0    ; OP_PUSH
  dd 0xf0    ; OP_POP
  dd 0x03    ; OP_ADD
  dd 0x2b    ; OP_SUB
  dd 0x8b    ; OP_MOV
  dd 0x3b    ; OP_CMP
  dd 0x23    ; OP_AND
  dd 0x0b    ; OP_OR
  dd 0xf0    ; OP_JMP
  dd 0xf0    ; OP_CALL
  dd 0xf0    ; OP_JE
  dd 0xf0    ; OP_JNE
  dd 0xf0    ; OP_JA
  dd 0xf0    ; OP_JNA
  dd 0xf0    ; OP_JAE
  dd 0xf0    ; OP_JNAE
  dd 0xf0    ; OP_JB
  dd 0xf0    ; OP_JNB
  dd 0xf0    ; OP_JBE
  dd 0xf0    ; OP_JNBE
  dd 0xf0    ; OP_JG
  dd 0xf0    ; OP_JNG
  dd 0xf0    ; OP_JGE
  dd 0xf0    ; OP_JNGE
  dd 0xf0    ; OP_JL
  dd 0xf0    ; OP_JNL
  dd 0xf0    ; OP_JLE
  dd 0xf0    ; OP_JNLE
  dd 0xf0    ; OP_MUL
  dd 0xf0    ; OP_IMUL
  dd 0xf0    ; OP_INT
  dd 0xf0    ; OP_RET

rm8r8_opcode:
  dd 0xf0    ; OP_PUSH
  dd 0xf0    ; OP_POP
  dd 0x00    ; OP_ADD
  dd 0x28    ; OP_SUB
  dd 0x88    ; OP_MOV
  dd 0x38    ; OP_CMP
  dd 0x20    ; OP_AND
  dd 0x08    ; OP_OR
  dd 0xf0    ; OP_JMP
  dd 0xf0    ; OP_CALL
  dd 0xf0    ; OP_JE
  dd 0xf0    ; OP_JNE
  dd 0xf0    ; OP_JA
  dd 0xf0    ; OP_JNA
  dd 0xf0    ; OP_JAE
  dd 0xf0    ; OP_JNAE
  dd 0xf0    ; OP_JB
  dd 0xf0    ; OP_JNB
  dd 0xf0    ; OP_JBE
  dd 0xf0    ; OP_JNBE
  dd 0xf0    ; OP_JG
  dd 0xf0    ; OP_JNG
  dd 0xf0    ; OP_JGE
  dd 0xf0    ; OP_JNGE
  dd 0xf0    ; OP_JL
  dd 0xf0    ; OP_JNL
  dd 0xf0    ; OP_JLE
  dd 0xf0    ; OP_JNLE
  dd 0xf0    ; OP_MUL
  dd 0xf0    ; OP_IMUL
  dd 0xf0    ; OP_INT
  dd 0xf0    ; OP_RET

rm32r32_opcode:
  dd 0xf0    ; OP_PUSH
  dd 0xf0    ; OP_POP
  dd 0x01    ; OP_ADD
  dd 0x29    ; OP_SUB
  dd 0x89    ; OP_MOV
  dd 0x39    ; OP_CMP
  dd 0x21    ; OP_AND
  dd 0x09    ; OP_OR
  dd 0xf0    ; OP_JMP
  dd 0xf0    ; OP_CALL
  dd 0xf0    ; OP_JE
  dd 0xf0    ; OP_JNE
  dd 0xf0    ; OP_JA
  dd 0xf0    ; OP_JNA
  dd 0xf0    ; OP_JAE
  dd 0xf0    ; OP_JNAE
  dd 0xf0    ; OP_JB
  dd 0xf0    ; OP_JNB
  dd 0xf0    ; OP_JBE
  dd 0xf0    ; OP_JNBE
  dd 0xf0    ; OP_JG
  dd 0xf0    ; OP_JNG
  dd 0xf0    ; OP_JGE
  dd 0xf0    ; OP_JNGE
  dd 0xf0    ; OP_JL
  dd 0xf0    ; OP_JNL
  dd 0xf0    ; OP_JLE
  dd 0xf0    ; OP_JNLE
  dd 0xf0    ; OP_MUL
  dd 0xf0    ; OP_IMUL
  dd 0xf0    ; OP_INT
  dd 0xf0    ; OP_RET

rm8imm8_opcode:
  dd 0xf0    ; OP_PUSH
  dd 0xf0    ; OP_POP
  dd 0x0080  ; OP_ADD
  dd 0x0580  ; OP_SUB
  dd 0x00c6  ; OP_MOV
  dd 0x0780  ; OP_CMP
  dd 0x0480  ; OP_AND
  dd 0x0180  ; OP_OR
  dd 0xf0    ; OP_JMP
  dd 0xf0    ; OP_CALL
  dd 0xf0    ; OP_JE
  dd 0xf0    ; OP_JNE
  dd 0xf0    ; OP_JA
  dd 0xf0    ; OP_JNA
  dd 0xf0    ; OP_JAE
  dd 0xf0    ; OP_JNAE
  dd 0xf0    ; OP_JB
  dd 0xf0    ; OP_JNB
  dd 0xf0    ; OP_JBE
  dd 0xf0    ; OP_JNBE
  dd 0xf0    ; OP_JG
  dd 0xf0    ; OP_JNG
  dd 0xf0    ; OP_JGE
  dd 0xf0    ; OP_JNGE
  dd 0xf0    ; OP_JL
  dd 0xf0    ; OP_JNL
  dd 0xf0    ; OP_JLE
  dd 0xf0    ; OP_JNLE
  dd 0xf0    ; OP_MUL
  dd 0xf0    ; OP_IMUL
  dd 0xf0    ; OP_INT
  dd 0xf0    ; OP_RET

rm32imm32_opcode:
  dd 0xf0    ; OP_PUSH
  dd 0xf0    ; OP_POP
  dd 0x0081  ; OP_ADD
  dd 0x0581  ; OP_SUB
  dd 0x00c7  ; OP_MOV
  dd 0x0781  ; OP_CMP
  dd 0x0481  ; OP_AND
  dd 0x0181  ; OP_OR
  dd 0xf0    ; OP_JMP
  dd 0xf0    ; OP_CALL
  dd 0xf0    ; OP_JE
  dd 0xf0    ; OP_JNE
  dd 0xf0    ; OP_JA
  dd 0xf0    ; OP_JNA
  dd 0xf0    ; OP_JAE
  dd 0xf0    ; OP_JNAE
  dd 0xf0    ; OP_JB
  dd 0xf0    ; OP_JNB
  dd 0xf0    ; OP_JBE
  dd 0xf0    ; OP_JNBE
  dd 0xf0    ; OP_JG
  dd 0xf0    ; OP_JNG
  dd 0xf0    ; OP_JGE
  dd 0xf0    ; OP_JNGE
  dd 0xf0    ; OP_JL
  dd 0xf0    ; OP_JNL
  dd 0xf0    ; OP_JLE
  dd 0xf0    ; OP_JNLE
  dd 0xf0    ; OP_MUL
  dd 0xf0    ; OP_IMUL
  dd 0xf0    ; OP_INT
  dd 0xf0    ; OP_RET


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

  global get_opcode_names
get_opcode_names:
  mov eax, opcode_names
  ret

  global get_opcode_funcs
get_opcode_funcs:
  mov eax, opcode_funcs
  ret

  global get_rm32_opcode
get_rm32_opcode:
  mov eax, rm32_opcode
  ret

  global get_imm32_opcode
get_imm32_opcode:
  mov eax, imm32_opcode
  ret

  global get_rm8r8_opcode
get_rm8r8_opcode:
  mov eax, rm8r8_opcode
  ret

  global get_rm32r32_opcode
get_rm32r32_opcode:
  mov eax, rm32r32_opcode
  ret

  global get_r8rm8_opcode
get_r8rm8_opcode:
  mov eax, r8rm8_opcode
  ret

  global get_r32rm32_opcode
get_r32rm32_opcode:
  mov eax, r32rm32_opcode
  ret

  global get_rm8imm8_opcode
get_rm8imm8_opcode:
  mov eax, rm8imm8_opcode
  ret

  global get_rm32imm32_opcode
get_rm32imm32_opcode:
  mov eax, rm32imm32_opcode
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
  sub eax, 1
trimstr_trim_loop2:
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
  jmp trimstr_trim_loop2

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
  ;; (and decode_number_or_symbol is permitted to fail in stage 0)
  push eax
  push 0
  mov ecx, esp

  push 0
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


  global emit_helper
emit_helper:
  push ebp
  mov ebp, esp

  ;; Check the opcode is valid and call first emit
  mov ecx, [ebp+8]
  mov edx, 0
  mov dl, cl
  cmp cl, 0xf0
  je platform_panic
  push edx
  call emit
  add esp, 4

  ;; Perhaps call second emit
  mov ecx, [ebp+8]
  and ecx, 0xff0000
  cmp ecx, 0
  je emit_helper_modrm
  mov ecx, [ebp+8]
  mov edx, 0
  mov dl, ch
  push edx
  call emit
  add esp, 4

emit_helper_modrm:
  ;; Perhaps call emit_modrm
  mov eax, [ebp+20]
  cmp eax, 0xffffffff
  je emit_helper_disp
  push eax
  mov edx, [ebp+16]
  cmp edx, 0xffffffff
  jne emit_helper_modrm3
  mov ecx, [ebp+8]
  mov edx, 0
  mov dl, ch
emit_helper_modrm3:
  push edx
  mov ecx, 2
  cmp DWORD [ebp+12], 0
  je emit_helper_modrm2
  mov ecx, 3
emit_helper_modrm2:
  push ecx
  call emit_modrm
  add esp, 12

emit_helper_disp:
  ;; Perhaps call emit32
  cmp DWORD [ebp+12], 0
  jne emit_helper_end
  mov edx, [ebp+24]
  push edx
  call emit32
  add esp, 4

emit_helper_end:
  pop ebp
  ret


  global process_jmp_like
process_jmp_like:
  push ebp
  mov ebp, esp

  ;; Allocate space for 5 variables:
  ;; [ebp-4], which is [ebp+0xfffffffc]: is_direct
  ;; [ebp-8], which is [ebp+0xfffffff8]: reg
  ;; [ebp-12], whch is [ebp+0xfffffff4]: disp
  ;; [ebp-16], which is [ebp+0xfffffff0]: is8
  ;; [ebp-20], which is [ebp+0xffffffec]: is32
  sub esp, 20

  ;; Call decode_operand
  mov eax, ebp
  sub eax, 20
  push eax
  mov eax, ebp
  sub eax, 16
  push eax
  mov eax, ebp
  sub eax, 12
  push eax
  mov eax, ebp
  sub eax, 8
  push eax
  mov eax, ebp
  sub eax, 4
  push eax
  mov eax, [ebp+12]
  push eax
  call decode_operand
  add esp, 24

  cmp eax, 0
  jne process_jmp_like_rm32
  jmp process_jmp_like_rel32

process_jmp_like_rm32:
  ;; Check the operand is not 8 bits
  cmp DWORD [ebp+0xfffffff0], 0
  jne platform_panic

  ;; Get the opcode data
  mov eax, [ebp+8]
  mov edx, 4
  imul edx
  add eax, rm32_opcode
  mov ecx, [eax]

  ;; Call emit_helper
  mov edx, [ebp+0xfffffff4]
  push edx
  mov edx, [ebp+0xfffffff8]
  push edx
  push 0xffffffff
  mov edx, [ebp+0xfffffffc]
  push edx
  push ecx
  call emit_helper
  add esp, 20

  jmp process_jmp_like_end

process_jmp_like_rel32:
  ;; Get the opcode data
  mov eax, [ebp+8]
  mov edx, 4
  imul edx
  add eax, imm32_opcode
  mov ecx, [eax]

  ;; Call emit_helper
  push 0
  push 0xffffffff
  push 0xffffffff
  push 1
  push ecx
  call emit_helper
  add esp, 20

  ;; Call decode_number_or_symbol
  push 0
  mov edx, esp
  push 0
  push edx
  mov edx, [ebp+12]
  push edx
  call decode_number_or_symbol
  add esp, 12

  ;; Check for success
  cmp eax, 0
  je platform_panic

  ;; Store the value in edx and make it relative
  pop edx
  mov ecx, current_loc
  sub edx, [ecx]
  sub edx, 4

  ;; Call emit32
  push edx
  call emit32
  add esp, 4

  jmp process_jmp_like_end

process_jmp_like_end:
  add esp, 20
  pop ebp
  ret


  global process_push_like
process_push_like:
  push ebp
  mov ebp, esp

  ;; Allocate space for 5 variables:
  ;; [ebp-4], which is [ebp+0xfffffffc]: is_direct
  ;; [ebp-8], which is [ebp+0xfffffff8]: reg
  ;; [ebp-12], whch is [ebp+0xfffffff4]: disp
  ;; [ebp-16], which is [ebp+0xfffffff0]: is8
  ;; [ebp-20], which is [ebp+0xffffffec]: is32
  sub esp, 20

  ;; Call decode_operand
  mov eax, ebp
  sub eax, 20
  push eax
  mov eax, ebp
  sub eax, 16
  push eax
  mov eax, ebp
  sub eax, 12
  push eax
  mov eax, ebp
  sub eax, 8
  push eax
  mov eax, ebp
  sub eax, 4
  push eax
  mov eax, [ebp+12]
  push eax
  call decode_operand
  add esp, 24

  cmp eax, 0
  jne process_push_like_rm32
  jmp process_push_like_imm32

process_push_like_rm32:
  ;; Check the operand is not 8 bits
  cmp DWORD [ebp+0xfffffff0], 0
  jne platform_panic

  ;; Get the opcode data
  mov eax, [ebp+8]
  mov edx, 4
  imul edx
  add eax, rm32_opcode
  mov ecx, [eax]

  ;; Call emit_helper
  mov edx, [ebp+0xfffffff4]
  push edx
  mov edx, [ebp+0xfffffff8]
  push edx
  push 0xffffffff
  mov edx, [ebp+0xfffffffc]
  push edx
  push ecx
  call emit_helper
  add esp, 20

  jmp process_push_like_end

process_push_like_imm32:
  ;; Check that the operation is push
  cmp DWORD [ebp+8], OP_PUSH
  jne platform_panic

  ;; Emit the operand
  push 0x68
  call emit
  add esp, 4

  ;; Call decode_number_or_symbol
  push 0
  mov edx, esp
  push 0
  push edx
  mov edx, [ebp+12]
  push edx
  call decode_number_or_symbol
  add esp, 12
  cmp eax, 0
  je platform_panic

  ;; Call emit32
  pop edx
  push edx
  call emit32
  add esp, 4

  jmp process_push_like_end

process_push_like_end:
  add esp, 20
  pop ebp
  ret


  global process_add_like
process_add_like:
  push ebp
  mov ebp, esp

  ;; Allocate a lot of local variables
  ;; [ebp-4], which is [ebp+0xfffffffc]: dest_is_direct
  ;; [ebp-8], which is [ebp+0xfffffff8]: dest_reg
  ;; [ebp-12], whch is [ebp+0xfffffff4]: dest_disp
  ;; [ebp-16], which is [ebp+0xfffffff0]: dest_is8
  ;; [ebp-20], which is [ebp+0xffffffec]: dest_is32
  ;; [ebp-24], which is [ebp+0xffffffe8]: src_is_direct
  ;; [ebp-28], which is [ebp+0xffffffe4]: src_reg
  ;; [ebp-32], which is [ebp+0xffffffe0]: src_disp
  ;; [ebp-36], which is [ebp+0xffffffdc]: src_is8
  ;; [ebp-40], which is [ebo+0xffffffd8]: src_is32
  sub esp, 40

  ;; Find the comma
  push COMMA
  mov edx, [ebp+12]
  push edx
  call find_char
  add esp, 8
  cmp eax, 0xffffffff
  je platform_panic

  ;; Substitute the comma with a terminator
  mov ecx, [ebp+12]
  add ecx, eax
  mov BYTE [ecx], 0

  ;; Push following position on the stack
  add ecx, 1
  push ecx

  ;; Call decode_operand for destination
  mov ecx, ebp
  sub ecx, 20
  push ecx
  mov ecx, ebp
  sub ecx, 16
  push ecx
  mov ecx, ebp
  sub ecx, 12
  push ecx
  mov ecx, ebp
  sub ecx, 8
  push ecx
  mov ecx, ebp
  sub ecx, 4
  push ecx
  mov ecx, [ebp+12]
  push ecx
  call decode_operand
  add esp, 24

  ;; Panic if decoding failed
  cmp eax, 0
  je platform_panic

  ;; Call decode_operand for source
  pop edx
  push edx
  mov ecx, ebp
  sub ecx, 40
  push ecx
  mov ecx, ebp
  sub ecx, 36
  push ecx
  mov ecx, ebp
  sub ecx, 32
  push ecx
  mov ecx, ebp
  sub ecx, 28
  push ecx
  mov ecx, ebp
  sub ecx, 24
  push ecx
  push edx
  call decode_operand
  add esp, 24
  pop edx

  cmp eax, 0
  je process_add_like_imm

  ;; Decide whether this is an 8 or 32 bits operation
  mov dl, [ebp+0xfffffff0]
  or dl, [ebp+0xffffffdc]
  mov dh, [ebp+0xffffffec]
  or dh, [ebp+0xffffffd8]

  ;; Check that the situation is consistent
  mov al, dl
  or al, dh
  cmp al, 0
  je platform_panic
  mov al, dl
  and al, dh
  cmp al, 0
  jne platform_panic

  ;; Split depending on whether destination is direct or not
  mov ecx, [ebp+0xfffffffc]
  cmp ecx, 0
  jne process_add_like_dest_direct
  jmp process_add_like_dest_indirect

process_add_like_dest_direct:
  ;; Split depending on 8 or 32 bits operation
  cmp dl, 0
  jne process_add_like_dest_direct_8
  jmp process_add_like_dest_direct_32

process_add_like_dest_direct_8:
  ;; Retrieve opcode_data
  mov eax, [ebp+8]
  mov edx, 4
  imul edx
  add eax, r8rm8_opcode
  mov ecx, [eax]

  ;; Call emit_helper
  mov eax, [ebp+0xffffffe0]
  push eax
  mov eax, [ebp+0xffffffe4]
  push eax
  mov eax, [ebp+0xfffffff8]
  push eax
  mov eax, [ebp+0xffffffe8]
  push eax
  push ecx
  call emit_helper
  add esp, 20

  jmp process_add_like_end

process_add_like_dest_direct_32:
  ;; Retrieve opcode_data
  mov eax, [ebp+8]
  mov edx, 4
  imul edx
  add eax, r32rm32_opcode
  mov ecx, [eax]

  ;; Call emit_helper
  mov eax, [ebp+0xffffffe0]
  push eax
  mov eax, [ebp+0xffffffe4]
  push eax
  mov eax, [ebp+0xfffffff8]
  push eax
  mov eax, [ebp+0xffffffe8]
  push eax
  push ecx
  call emit_helper
  add esp, 20

  jmp process_add_like_end

process_add_like_dest_indirect:
  ;; Check that source is direct
  cmp DWORD [ebp+0xffffffe8], 0
  je platform_panic

  ;; Split depending on 8 or 32 bits operation
  cmp dl, 0
  jne process_add_like_dest_indirect_8
  jmp process_add_like_dest_indirect_32

process_add_like_dest_indirect_8:
  ;; Retrieve opcode_data
  mov eax, [ebp+8]
  mov edx, 4
  imul edx
  add eax, rm8r8_opcode
  mov ecx, [eax]

  ;; Call emit_helper
  mov eax, [ebp+0xfffffff4]
  push eax
  mov eax, [ebp+0xfffffff8]
  push eax
  mov eax, [ebp+0xffffffe4]
  push eax
  push 0
  push ecx
  call emit_helper
  add esp, 20

  jmp process_add_like_end

process_add_like_dest_indirect_32:
  ;; Retrieve opcode_data
  mov eax, [ebp+8]
  mov edx, 4
  imul edx
  add eax, rm32r32_opcode
  mov ecx, [eax]

  ;; Call emit_helper
  mov eax, [ebp+0xfffffff4]
  push eax
  mov eax, [ebp+0xfffffff8]
  push eax
  mov eax, [ebp+0xffffffe4]
  push eax
  push 0
  push ecx
  call emit_helper
  add esp, 20

  jmp process_add_like_end

process_add_like_imm:
  ;; Check that we know the operation size
  mov eax, [ebp+0xfffffff0]
  or eax, [ebp+0xffffffec]
  cmp eax, 0
  je platform_panic

  ;; Call decode_number_or_symbol
  push 0
  mov ecx, esp
  push 0
  push ecx
  push edx
  call decode_number_or_symbol
  add esp, 12
  pop edx

  ;; Check it did work
  cmp eax, 0
  je platform_panic

  cmp DWORD [ebp+0xfffffff0], 0
  je process_add_like_imm_32
  jmp process_add_like_imm_8

process_add_like_imm_8:
  push edx

  ;; Retrieve opcode_data
  mov eax, [ebp+8]
  mov edx, 4
  imul edx
  add eax, rm8imm8_opcode
  mov ecx, [eax]

  ;; Call emit_helper
  mov eax, [ebp+0xfffffff4]
  push eax
  mov eax, [ebp+0xfffffff8]
  push eax
  push 0xffffffff
  mov eax, [ebp+0xfffffffc]
  push eax
  push ecx
  call emit_helper
  add esp, 20

  ;; Call emit
  pop edx
  push edx
  call emit
  add esp, 4

  jmp process_add_like_end

process_add_like_imm_32:
  push edx

  ;; Retrieve opcode_data
  mov eax, [ebp+8]
  mov edx, 4
  imul edx
  add eax, rm32imm32_opcode
  mov ecx, [eax]

  ;; Call emit_helper
  mov eax, [ebp+0xfffffff4]
  push eax
  mov eax, [ebp+0xfffffff8]
  push eax
  push 0xffffffff
  mov eax, [ebp+0xfffffffc]
  push eax
  push ecx
  call emit_helper
  add esp, 20

  ;; Call emit
  pop edx
  push edx
  call emit32
  add esp, 4

  jmp process_add_like_end

process_add_like_end:
  add esp, 40
  pop ebp
  ret


  global process_int
process_int:
  ;; Check the operation is actually an int
  cmp DWORD [esp+4], OP_INT
  jne platform_panic

  ;; Call decode_number_or_symbol
  push 0
  mov edx, esp
  push 0
  push edx
  mov edx, [esp+8]
  push edx
  call decode_number_or_symbol
  add esp, 12
  pop edx

  ;; Check result
  cmp eax, 0
  je platform_panic

  ;; Check the interrupt number is smaller than 0x100
  cmp edx, 0x100
  jnb platform_panic

  ;; Call emit twice
  push edx
  push 0xcd
  call emit
  add esp, 4
  call emit
  add esp, 4

  ret


  global process_ret
process_ret:
  ;; Check the operation is actually a ret
  cmp DWORD [esp+4], OP_RET
  jne platform_panic

  ;; Check that data is empty
  mov edx, [esp+8]
  cmp BYTE [edx], 0
  jne platform_panic

  ;; Call emit
  push 0xc3
  call emit
  add esp, 4

  ret


  global process_text_line
process_text_line:
  push ebp
  mov ebp, esp
  push esi
  push edi

  ;; Init esi for storing the current name and edi for counting
  mov esi, opcode_names
  mov edi, 0

process_text_line_loop:
  ;; Check for termination: we did not find any match
  mov eax, 0
  cmp BYTE [esi], 0
  je process_text_line_end

  ;; Check for termination: we found a match
  mov ecx, [ebp+8]
  push ecx
  push esi
  call strcmp
  add esp, 8
  cmp eax, 0
  je process_text_line_match

  ;; Consume the string and increment the index
  push esi
  call strlen
  add esp, 4
  add esi, eax
  add esi, 1
  add edi, 1

  jmp process_text_line_loop

process_text_line_match:
  ;; Select the opcode function
  mov eax, 4
  imul edi
  add eax, opcode_funcs

  ;; Call the opcode function
  mov edx, [ebp+12]
  push edx
  push edi
  call [eax]
  add esp, 8

  mov eax, 1
  jmp process_text_line_end

process_text_line_end:
  pop edi
  pop esi
  pop ebp
  ret
