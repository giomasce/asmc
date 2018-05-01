
  WRITE_LABEL_BUF_LEN equ 128
  STACK_LEN equ 1024
  ;; STACK_SIZE = STACK_LEN * MAX_SYMBOL_NAME_LEN
  STACK_SIZE equ 131072

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

read_fd:
  resd 1

write_label_buf:
  resb WRITE_LABEL_BUF_LEN

  section .text

  global get_label_num
get_label_num:
  mov eax, label_num
  ret

  global get_stack_vars
get_stack_vars:
  mov eax, stack_vars_ptr
  mov eax, [eax]
  ret

  global get_block_depth
get_block_depth:
  mov eax, block_depth
  ret

  global get_stack_depth
get_stack_depth:
  mov eax, stack_depth
  ret

  global get_temp_depth
get_temp_depth:
  mov eax, temp_depth
  ret

  global get_token_given_back
get_token_given_back:
  mov eax, token_given_back
  ret

  global get_token_len
get_token_len:
  mov eax, token_len
  ret

  global get_token_buf
get_token_buf:
  mov eax, token_buf_ptr
  mov eax, [eax]
  ret

  global get_buf2
get_buf2:
  mov eax, buf2_ptr
  mov eax, [eax]
  ret

  global get_read_fd
get_read_fd:
  mov eax, read_fd
  ret


  global gen_label
gen_label:
  ;; Increment by 1 gen_label and return its original value
  mov ecx, label_num
  mov eax, [ecx]
  mov edx, eax
  add edx, 1
  mov [ecx], edx
  ret


  global write_label
write_label:
  ;; Call itoa
  mov eax, [esp+4]
  push eax
  call itoa
  add esp, 4
  mov edx, eax

  ;; Print the initial dot
  mov eax, write_label_buf
  mov BYTE [eax], DOT

  ;; Copy from itoa to our buffer
  add eax, 1
  push edx
  push eax
  call strcpy
  add esp, 8

  mov eax, write_label_buf
  ret


  global get_symbol
get_symbol:
  ;; If stage is not 1 and no arity is requested, just return 0
  mov eax, stage
  cmp DWORD [eax], 1
  je get_symbol_find
  cmp DWORD [esp+8], 0
  jne get_symbol_find
  mov eax, 0
  ret

get_symbol_find:
  ;; Call find_symbol
  mov ecx, [esp+8]
  mov eax, [esp+4]
  push 0
  mov edx, esp
  push ecx
  push edx
  push eax
  call find_symbol
  add esp, 12

  ;; Check for validity
  cmp eax, 0
  je platform_panic

  ;; Return the location
  pop eax
  ret


  global is_whitespace
is_whitespace:
  ;; Return true only if the argument is a tab, a space or a newline
  mov ecx, [esp+4]
  cmp cl, SPACE
  je is_whitespace_ret_true
  cmp cl, TAB
  je is_whitespace_ret_true
  cmp cl, NEWLINE
  je is_whitespace_ret_true
  mov eax, 0
  ret

is_whitespace_ret_true:
  mov eax, 1
  ret


  global push_var
push_var:
  ;; Check the var name length
  mov eax, [esp+4]
  push eax
  call strlen
  add esp, 4
  cmp eax, 0
  jna platform_panic
  cmp eax, MAX_SYMBOL_NAME_LEN
  jnb platform_panic

  ;; Check we are not overflowing the stack
  mov eax, stack_depth
  mov eax, [eax]
  cmp eax, STACK_LEN
  jnb platform_panic

  ;; Copy the variable name in the stack
  mov edx, MAX_SYMBOL_NAME_LEN
  mul edx
  mov ecx, stack_vars_ptr
  add eax, [ecx]
  mov edx, eax
  mov eax, [esp+4]
  push eax
  push edx
  call strcpy
  add esp, 8

  ;; Increment the stack depth
  mov eax, stack_depth
  add DWORD [eax], 1

  ;; If this is a temp var, increment also temp_depth
  cmp DWORD [esp+8], 0
  je push_var_non_temp
  mov eax, temp_depth
  add DWORD [eax], 1
  ret

  ;; If this is not a temp var, check temp_depth is zero
push_var_non_temp:
  mov eax, temp_depth
  cmp DWORD [eax], 0
  jne platform_panic
  ret


  global pop_var
pop_var:
  ;; Check stack depth is positive and decrement it
  mov eax, stack_depth
  cmp DWORD [eax], 0
  jna platform_panic
  sub DWORD [eax], 1

  ;; If this is a temp var...
  cmp DWORD [esp+4], 0
  jne pop_var_temp
  ret

  ;; ...check and decrement temp_depth
pop_var_temp:
  mov eax, temp_depth
  cmp DWORD [eax], 0
  jna platform_panic
  sub DWORD [eax], 1
  ret


  global pop_temps
pop_temps:
  ;; Check for termination
  mov eax, temp_depth
  cmp DWORD [eax], 0
  jna pop_temps_ret

  ;; Call pop_var
  push 1
  call pop_var
  add esp, 4

  jmp pop_temps

pop_temps_ret:
  ret


  global find_in_stack
find_in_stack:
  push ebp
  mov ebp, esp
  push ebx
  mov ebx, 0

find_in_stack_loop:
  ;; Check for termination
  mov edx, stack_depth
  cmp ebx, [edx]
  mov eax, 1
  je find_in_stack_end

  ;; Compute the pointer to be checked
  mov eax, [edx]
  sub eax, 1
  sub eax, ebx
  mov edx, MAX_SYMBOL_NAME_LEN
  mul edx
  mov ecx, stack_vars_ptr
  add eax, [ecx]

  ;; Call strcmp and return if it matches
  push eax
  push DWORD [ebp+8]
  call strcmp
  add esp, 8
  cmp eax, 0
  je find_in_stack_found

  ;; Increment index and restart
  add ebx, 1
  jmp find_in_stack_loop

find_in_stack_found:
  mov eax, ebx

find_in_stack_end:
  pop ebx
  pop ebp
  ret


  global get_token
get_token:
  ;; If last token was given back, just return it
  mov eax, token_given_back
  cmp DWORD [eax], 0
  je get_token_read
  mov DWORD [eax], 0
  mov eax, token_buf_ptr
  mov eax, [eax]
  ret

get_token_read:
  push ebx

  ;; Reset length and state
  mov eax, token_len
  mov DWORD [eax], 0
  mov ecx, 0

get_token_loop:
  ;; Call platform_read_char
  push ecx
  mov ecx, read_fd
  push DWORD [ecx]
  call platform_read_char
  add esp, 4

  ;; Break if -1 was returned
  pop ecx
  cmp eax, 0xffffffff
  je get_token_end
  push ecx

  ;; Call is_whitespace
  push eax
  push eax
  call is_whitespace
  add esp, 4

  ;; Store is_whitespace in eax, save_char in dh, read char in dl and
  ;; state in ecx
  pop edx
  mov dh, 0
  pop ecx

  ;; Branch depending on the state
  cmp ecx, 0
  je get_token_state0
  cmp ecx, 1
  je get_token_state1
  cmp ecx, 2
  je get_token_state2
  cmp ecx, 3
  je get_token_state3
  call platform_panic

  ;; Normal program code
get_token_state0:
  cmp eax, 0
  jne get_token_state0_whitespace
  cmp dl, POUND
  je get_token_state0_pound
  mov dh, 1
  cmp dl, QUOTE
  je get_token_state0_quote
  jmp get_token_loop_end

get_token_state0_whitespace:
  mov eax, token_len
  cmp DWORD [eax], 0
  ja get_token_end
  jmp get_token_loop_end

get_token_state0_pound:
  mov ecx, 1
  jmp get_token_loop_end

get_token_state0_quote:
  mov ecx, 2
  jmp get_token_loop_end

  ;; Comments
get_token_state1:
  cmp dl, NEWLINE
  jne get_token_loop_end
  mov ecx, 0
  mov eax, token_len
  cmp DWORD [eax], 0
  ja get_token_end
  jmp get_token_loop_end

  ;; String
get_token_state2:
  mov dh, 1
  cmp dl, QUOTE
  je get_token_state2_quote
  cmp dl, BACKSLASH
  je get_token_state2_backslash
  jmp get_token_loop_end

get_token_state2_quote:
  mov ecx, 0
  jmp get_token_loop_end

get_token_state2_backslash:
  mov ecx, 3
  jmp get_token_loop_end

  ;; Escape character in a string
get_token_state3:
  mov ecx, 2
  mov dh, 1
  jmp get_token_loop_end

get_token_loop_end:
  ;; If save_char is true, save the char and increment length
  cmp dh, 0
  je get_token_loop
  mov ebx, token_len
  mov ebx, [ebx]
  mov eax, token_buf_ptr
  mov eax, [eax]
  add eax, ebx
  mov [eax], dl
  add ebx, 1
  mov eax, token_len
  mov [eax], ebx

  jmp get_token_loop

get_token_end:
  ;; Write the terminator and return
  mov eax, token_buf_ptr
  mov eax, [eax]
  mov ecx, token_len
  mov ecx, [ecx]
  add ecx, eax
  mov BYTE [ecx], 0

  pop ebx
  ret


  global give_back_token
give_back_token:
  ;; Check another token was not already given back
  mov eax, token_given_back
  cmp DWORD [eax], 0
  jne platform_panic

  ;; Mark the current one as given back
  mov DWORD [eax], 1
  ret


  global init_g_compiler
init_g_compiler:
  ;; Allocate stack variables list
  push STACK_SIZE
  call platform_allocate
  add esp, 4
  mov ecx, stack_vars_ptr
  mov [ecx], eax

  ;; Allocate the token buffer
  push MAX_SYMBOL_NAME_LEN
  call platform_allocate
  add esp, 4
  mov ecx, token_buf_ptr
  mov [ecx], eax

  ;; Allocate buf2
  push MAX_SYMBOL_NAME_LEN
  call platform_allocate
  add esp, 4
  mov ecx, buf2_ptr
  mov [ecx], eax

  ;; Set token_given_back to false
  mov eax, token_given_back
  mov DWORD [eax], 0

  ret
