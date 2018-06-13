
first:
  add eax, ebx                  ; Test line
  add eax, 0x2200
  add al, 0x22
second:
  add byte [eax+second+eax], 0x22
  add ebx, [eax+second+eax]
  add bh, [eax+second+eax]
  add dword [eax+second+eax], 0x22
  add al, second

  mul edx
  mul BYTE [edx]
  mul dWoRd [edx+ebx*4+0x2244]

  jmp first
  jmp second
  jmp [eax]
  jmp [eax+ebx*2]

third:
  jz third
  je third
  ja third
  jna third
  jc third
