
str_helloasm:
  db 'Hello, ASM!'
  db 0xa
  db 0

greetings:
  ;; Greetings!
  push str_helloasm
  push 1
  ;; call platform_log
  add esp, 8
  ret
