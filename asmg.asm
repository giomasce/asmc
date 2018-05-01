
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


  global init_g_compiler
init_g_compiler:
  ;; Allocate stack variables list
  push STACK_SIZE
  call platform_allocate
  add esp, 4
  mov ecx, stack_vars_ptr
  mov [ecx], eax

  ret
