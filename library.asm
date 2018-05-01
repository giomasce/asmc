
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
  SEMICOLON equ 0x3b
  COLON equ 0x3a
  DOT equ 0x2e
  QUOTE equ 0x22
  BACKSLASH equ 0x5c
  POUND equ 0x23

  ITOA_BUF_LEN equ 32

  INPUT_BUF_LEN equ 1024
  MAX_SYMBOL_NAME_LEN equ 128
  SYMBOL_TABLE_LEN equ 1024
  ;; SYMBOL_TABLE_SIZE = SYMBOL_TABLE_LEN * MAX_SYMBOL_NAME_LEN
  SYMBOL_TABLE_SIZE equ 131072

section .bss

itoa_buf:
  resb ITOA_BUF_LEN

symbol_names_ptr:
  resd 1

symbol_locs_ptr:
  resd 1

symbol_arities_ptr:
  resd 1

symbol_num:
  resd 1

current_loc:
  resd 1

stage:
  resd 1

emit_fd:
  resd 1

section .text

  global get_symbol_names
get_symbol_names:
  mov eax, symbol_names_ptr
  mov eax, [eax]
  ret

  global get_symbol_locs
get_symbol_locs:
  mov eax, symbol_locs_ptr
  mov eax, [eax]
  ret

  global get_symbol_arities
get_symbol_arities:
  mov eax, symbol_arities_ptr
  mov eax, [eax]
  ret

  global get_symbol_num
get_symbol_num:
  mov eax, symbol_num
  ret

  global get_current_loc
get_current_loc:
  mov eax, current_loc
  ret

  global get_stage
get_stage:
  mov eax, stage
  ret

  global get_emit_fd
get_emit_fd:
  mov eax, emit_fd
  ret


  ;; char *itoa(int x)
  global itoa
itoa:
  ;; Clear the buffer
  mov ecx, ITOA_BUF_LEN
  mov eax, itoa_buf

itoa_clear_loop:
  cmp ecx, 0
  je itoa_cleared
  mov BYTE [eax], SPACE
  add eax, 1
  sub ecx, 1
  jmp itoa_clear_loop

itoa_cleared:
  ;; Prepare registers
  mov eax, [esp+4]
  push esi
  mov esi, 10
  mov ecx, itoa_buf
  add ecx, ITOA_BUF_LEN
  sub ecx, 1

  ;; Store a terminator at the end
  mov BYTE [ecx], 0
  sub ecx, 1

itoa_loop:
  ;; Divide by the base
  mov edx, 0
  div esi

  ;; Output the remainder
  add edx, ZERO
  mov [ecx], dl

  ;; Check for termination
  cmp eax, 0
  je itoa_end

  ;; Move the pointer backwards
  sub ecx, 1

  jmp itoa_loop

itoa_end:
  mov eax, ecx
  pop esi
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
  mov edx, emit_fd
  push ecx
  push DWORD [edx]
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


  global emit_str
emit_str:
  ;; Check for termination
  cmp DWORD [esp+8], 0
  je emit_str_ret

  ;; Call emit
  mov eax, [esp+4]
  mov edx, 0
  mov dl, [eax]
  push edx
  call emit
  add esp, 4

  ;; Increment/decrement and repeat
  add DWORD [esp+4], 1
  sub DWORD [esp+8], 1
  jmp emit_str

emit_str_ret:
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
  mul edx
  jmp decode_number_after_mult
decode_number_mult16:
  mov edx, 16
  mul edx

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


  ;; int atoi(char*)
  global atoi
atoi:
  ;; Call decode_number, adapting the parameters
  mov ecx, [esp+4]
  push 0
  mov edx, esp
  push edx
  push ecx
  call decode_number
  add esp, 8
  cmp eax, 0
  pop eax
  je platform_panic
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
  push SYMBOL_TABLE_SIZE
  call platform_allocate
  add esp, 4
  mov ecx, symbol_names_ptr
  mov [ecx], eax

  ;; Allocate symbol locations table
  mov eax, SYMBOL_TABLE_LEN
  mov edx, 4
  mul eax
  push eax
  call platform_allocate
  add esp, 4
  mov ecx, symbol_locs_ptr
  mov [ecx], eax

  ;; Allocate symbol arities table
  mov eax, SYMBOL_TABLE_LEN
  mov edx, 4
  mul eax
  push eax
  call platform_allocate
  add esp, 4
  mov ecx, symbol_arities_ptr
  mov [ecx], eax

  ;; Reset symbol_num
  mov eax, symbol_num
  mov DWORD [eax], 0

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
  mul edx
  mov ecx, symbol_names_ptr
  add eax, [ecx]
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
  ;; If the second argument is not null, fill it with the location
  mov edx, [ebp+12]
  cmp edx, 0
  je find_symbol_arity
  mov eax, 4
  mul ecx
  mov edx, symbol_locs_ptr
  add eax, [edx]
  mov eax, [eax]
  mov edx, [ebp+12]
  mov [edx], eax

find_symbol_arity:
  ;; If the third argument is not null, fill it with the arity
  mov edx, [ebp+16]
  cmp edx, 0
  je find_symbol_ret_found
  mov eax, 4
  mul ecx
  mov edx, symbol_arities_ptr
  add eax, [edx]
  mov eax, [eax]
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
  mul ecx
  mov ecx, symbol_locs_ptr
  add eax, [ecx]
  mov ecx, [ebp+12]
  mov [eax], ecx

  ;; Save the arity for the new symbol
  mov eax, ebx
  mov ecx, 4
  mul ecx
  mov ecx, symbol_arities_ptr
  add eax, [ecx]
  mov ecx, [ebp+16]
  mov [eax], ecx

  ;; Save the name for the new symbol
  mov eax, [ebp+8]
  push eax
  mov eax, ebx
  mov ecx, MAX_SYMBOL_NAME_LEN
  mul ecx
  mov ecx, symbol_names_ptr
  add eax, [ecx]
  push eax
  call strcpy
  add esp, 8

  ;; Increment and store the new symbol number
  add ebx, 1
  mov eax, symbol_num
  mov [eax], ebx

  pop ebx
  pop ebp
  ret


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
