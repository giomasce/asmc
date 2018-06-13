
test:
  add eax, ebx                  ; Test line
  add eax, 0x2200
  mul edx

  add al, 0x22
second:
  add byte [eax+second+eax], 0x22
  add al, second
