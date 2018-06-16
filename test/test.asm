
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
  neg BYTE [edx]
  not dWoRd [edx+ebx*4+0x2244]

  jmp first
  call second
  jmp [eax]
  call [eax+ebx*2]

third:
  jz third
  je third
  ja third
  jna third
  jc third

  ret

  push eax
  push ebx
  push [eax+ebx*2+first]
  push first
  push 0xff5500
  pop eax
  pop ebx

  int 0x80

  sal al, 10
  sal DWORD [eax], 12
  sal BYTE [eax], 12

  dd 0x11223344
  rw 2

  db 'Hello world!',0xa,0
