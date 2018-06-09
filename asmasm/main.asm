
str_helloasm:
  db 'Hello, ASM!'
  db 0xa
  db 0

str_atapio_asm:
  db 'atapio.asm'
  db 0
str_atapio_test_asm:
  db 'atapio_test.asm'
  db 0
str_atapio_test:
  db 'atapio_test'
  db 0

main:
  ;; Greetings!
  push str_helloasm
  push 1
  call platform_log
  add esp, 8

  ;; Compile the ATA PIO driver
  push str_atapio_asm
  call platform_assemble
  add esp, 4

  ;; Compile the ATA PIO test
  push str_atapio_test_asm
  call platform_assemble
  add esp, 4

  ;; Call atapio_test
  push 0
  push str_atapio_test
  call platform_get_symbol
  add esp, 8
  call eax

  ret
