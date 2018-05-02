
str_empty:
  db 'Unfortunately this is an empty kernel. You will not have fun here...'
  db NEWLINE
  db 0

start:
  ;; Log a sad message...
  push str_empty
  push 1
  call platform_log
  add esp, 8

  ret
