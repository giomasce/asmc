;; This file is part of asmc, a bootstrapping OS with minimal seed
;; Copyright (C) 2018-2019 Giovanni Mascellani <gio@debian.org>
;; https://gitlab.com/giomasce/asmc

;; This program is free software: you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.

;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with this program.  If not, see <https://www.gnu.org/licenses/>.

dump_multiboot:
  push ebp
  mov ebp, esp
  push ebx
  push esi

  ;; Save multiboot location
  mov ebx, [ebp+8]

  ;; Log
  push str_dump_multiboot
  push 1
  call platform_log
  add esp, 8

  ;; Check mem_lower and mem_upper are supported
  mov eax, [ebx]
  test eax, 1
  je dump_multiboot_mmap

  ;; Print mem_lower
  push str_mem_lower
  push 1
  call platform_log
  add esp, 8
  mov eax, [ebx+4]
  push eax
  call itoa
  add esp, 4
  push eax
  push 1
  call platform_log
  add esp, 8
  push str_newline
  push 1
  call platform_log
  add esp, 8

  ;; Print mem_upper
  push str_mem_upper
  push 1
  call platform_log
  add esp, 8
  mov eax, [ebx+8]
  push eax
  call itoa
  add esp, 4
  push eax
  push 1
  call platform_log
  add esp, 8
  push str_newline
  push 1
  call platform_log
  add esp, 8

dump_multiboot_mmap:
  ;; Check mmap_* are supported
  mov eax, [ebx]
  test eax, 64
  je dump_multiboot_end

  ;; Save mmap buffer in registers
  mov esi, [ebx+48]
  mov ebx, [ebx+44]
  add ebx, esi

dump_multiboot_mmap_dump:
  ;; Call mmap_dump
  push esi
  call mmap_dump
  add esp, 4

  ;; Increment pointer
  add esi, [esi]
  add esi, 4

  cmp esi, ebx
  jb dump_multiboot_mmap_dump

dump_multiboot_end:
  pop esi
  pop ebx
  pop ebp
  ret


mmap_dump:
  push ebp
  mov ebp, esp
  push ebx

  mov ebx, [ebp+8]

  ;; Check that ignored fields are not used
  cmp DWORD [ebx+8], 0
  jne platform_panic
  cmp DWORD [ebx+16], 0
  jne platform_panic

  ;; Print size
  ;; push str_mmap_size
  ;; push 1
  ;; call platform_log
  ;; add esp, 8
  ;; mov eax, [ebx]
  ;; push eax
  ;; call itoa
  ;; add esp, 4
  ;; push eax
  ;; push 1
  ;; call platform_log
  ;; add esp, 8
  ;; push str_newline
  ;; push 1
  ;; call platform_log
  ;; add esp, 8

  ;; Print base_addr
  ;; push str_mmap_base_addr
  ;; push 1
  ;; call platform_log
  ;; add esp, 8
  push str_mmap
  push 1
  call platform_log
  add esp, 8
  mov eax, [ebx+4]
  push eax
  call itoa
  add esp, 4
  push eax
  push 1
  call platform_log
  add esp, 8
  ;; push str_newline
  ;; push 1
  ;; call platform_log
  ;; add esp, 8

  ;; Print length
  ;; push str_mmap_length
  ;; push 1
  ;; call platform_log
  ;; add esp, 8
  push str_slash
  push 1
  call platform_log
  add esp, 8
  mov eax, [ebx+12]
  push eax
  call itoa
  add esp, 4
  push eax
  push 1
  call platform_log
  add esp, 8
  ;; push str_newline
  ;; push 1
  ;; call platform_log
  ;; add esp, 8

  ;; Print type
  ;; push str_mmap_type
  ;; push 1
  ;; call platform_log
  ;; add esp, 8
  push str_slash
  push 1
  call platform_log
  add esp, 8
  mov eax, [ebx+20]
  push eax
  call itoa
  add esp, 4
  push eax
  push 1
  call platform_log
  add esp, 8
  push str_newline
  push 1
  call platform_log
  add esp, 8

  pop ebx
  pop ebp
  ret

str_dump_multiboot:
  db 'Dumping multiboot boot information...'
  db NEWLINE
  db 0
str_mem_lower:
  db 'mem_lower = '
  db 0
str_mem_upper:
  db 'mem_lower = '
  db 0
str_mmap:
  db 'Memory region: '
  db 0
str_slash:
  db ' / '
  db 0
