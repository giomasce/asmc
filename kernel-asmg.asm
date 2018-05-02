
str_platform_g_compile:
  db 'platform_g_compile'
  db 0

str_init_compile_main:
  db 'Will now assemble compile main.g...'
  db NEWLINE
  db 0
str_init_launch_main:
  db 'Will now call main!'
  db NEWLINE
  db 0

str_main_g:
  db 'main.g'
  db 0
str_main:
  db 'main'
  db 0


  ;; void platform_g_compile(char *filename)
platform_g_compile:
  ;; Prepare to write in memory
  mov eax, write_mem_ptr
  mov ecx, heap_ptr
  mov edx, [ecx]
  mov [eax], edx

  ;; Load the parameter and save some registers
  mov eax, [esp+4]
  push edx
  push edx

  ;; Open the file
  push eax
  call platform_open_file
  add esp, 4
  pop edx

  ;; Assemble the file
  push 0
  push edx
  push 0
  push eax
  call compile
  add esp, 16

  ;; Actually allocate used heap memory, so that new allocations will
  ;; not overwrite it
  mov eax, write_mem_ptr
  mov ecx, heap_ptr
  mov edx, [eax]
  sub edx, [ecx]
  push edx
  call platform_allocate
  add esp, 4

  ;; Assert that the allocation gave us what we expected
  pop edx
  cmp edx, eax
  jne platform_panic

  ret


start:
  ;; Init compiler
  call init_g_compiler
  call init_g_operations
  push 1
  push platform_g_compile
  push str_platform_g_compile
  call add_symbol
  add esp, 12

  ;; Log
  push str_init_compile_main
  push 1
  call platform_log
  add esp, 8

  ;; Assemble main.asm
  push str_main_g
  call platform_g_compile
  add esp, 4

  ;; Log
  push str_init_launch_main
  push 1
  call platform_log
  add esp, 8

  ;; Call main
  push 0
  push str_main
  call platform_get_symbol
  add esp, 8
  call eax

  ret

str_equal:
  db '='
  db 0
equal:
  mov eax, [esp+4]
  mov ecx, [esp+8]
  mov [ecx], eax
  ret

str_param:
  db 'param'
  db 0
param:
  mov eax, [esp+4]
  mov edx, 4
  mul edx
  add eax, 8
  add eax, ebp
  mov eax, [eax]
  ret

str_plus:
  db '+'
  db 0
plus:
  mov eax, [esp+8]
  add eax, [esp+4]
  ret

str_minus:
  db '-'
  db 0
minus:
  mov eax, [esp+8]
  sub eax, [esp+4]
  ret

str_atoi:
  db 'atoi'
  db 0
str_itoa:
  db 'itoa'
  db 0


init_g_operations:
  push 2
  push equal
  push str_equal
  call add_symbol
  add esp, 12

  push 1
  push param
  push str_param
  call add_symbol
  add esp, 12

  push 2
  push plus
  push str_plus
  call add_symbol
  add esp, 12

  push 2
  push minus
  push str_minus
  call add_symbol
  add esp, 12

  push 1
  push atoi
  push str_atoi
  call add_symbol
  add esp, 12

  push 1
  push itoa
  push str_itoa
  call add_symbol
  add esp, 12

  ret
