
  extern platform_panic
  extern platform_exit
  extern platform_open_file
  extern platform_reset_file
  extern platform_read_char
  extern platform_write_char
  extern platform_log
  extern platform_allocate

  section .data

  global main
main:
  ;; Init everything
  call init_symbols
  call init_assembler

  ;; Open input file
  mov eax, [esp+8]
  add eax, 4
  mov eax, [eax]
  push eax
  call platform_open_file
  add esp, 4

  ;; Call assemble
  push 0x100000
  push 1
  push eax
  call assemble
  add esp, 12

  mov eax, 0
  ret
