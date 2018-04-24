
  extern platform_panic
  extern platform_exit
  extern platform_open_file
  extern platform_reset_file
  extern platform_read_char
  extern platform_write_char
  extern platform_log

  extern assemble_file

  %include 'asmasm.asm'

  global  _start
_start:
  call assemble_file
  call platform_exit
