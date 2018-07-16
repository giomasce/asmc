;; This file is part of asmc, a bootstrapping OS with minimal seed
;; Copyright (C) 2018 Giovanni Mascellani <gio@debian.org>
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

str_platform_assemble:
  db 'platform_assemble'
  db 0

str_init_assemble_main:
  db 'Will now assemble main.asm...'
  db NEWLINE
  db 0
str_init_launch_main:
  db 'Will now call main!'
  db NEWLINE
  db 0

str_main_asm:
  db 'main.asm'
  db 0
str_main:
  db 'main'
  db 0

  ;; void platform_assemble(char *filename)
platform_assemble:
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
  push edx
  push 0
  push eax
  call assemble
  add esp, 12

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
  ;; Init assembler and register platform_assemble
  call init_assembler
  push 1
  push platform_assemble
  push str_platform_assemble
  call add_symbol
  add esp, 12

  ;; Log
  push str_init_assemble_main
  push 1
  call platform_log
  add esp, 8

  ;; Assemble main.asm
  push str_main_asm
  call platform_assemble
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
