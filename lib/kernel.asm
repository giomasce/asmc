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

  STACK_SIZE equ 65536
  ;; STACK_SIZE equ 8388608

  MAX_OPEN_FILE_NUM equ 1024
  FILE_RECORD_SIZE equ 16
  FILE_RECORD_SIZE_LOG equ 4

heap_ptr:
  resd 1

str_exit:
  db 'The execution has finished, bye bye...'
  db NEWLINE
  db 0
str_panic:
  db 'PANIC!'
  db NEWLINE
  db 0

str_hello_asmc:
  db 'Hello, asmc!'
  db NEWLINE
  db 0

str_init_asm_symbols_table:
  db 'Initializing symbols table... '
  db 0
str_done:
  db 'done!'
  db NEWLINE
  db 0

str_empty:
  db 0

entry:
  ;; Make it double sure that we do not have interrupts around
  cli

  ;; Use the multiboot header as temporary stack
  mov esp, temp_stack_top
  and esp, 0xfffffff0

  ;; Find the end of the ar initrd
  mov ecx, str_empty
  call walk_initrd

  ;; Initialize the stack and the heap, aligning to 16 bytes
  sub edx, 1
  or edx, 0xf
  add edx, 1
  add edx, STACK_SIZE
  mov esp, edx
  mov [heap_ptr], edx

  ;; Initialize stdout
  call stdout_setup

  ;; Log
  mov esi, str_hello_asmc
  call log

  ;; Log
  mov esi, str_init_asm_symbols_table
  call log

  ;; Init symbol table
  call init_symbols

  ;; Expose some kernel symbols
  call init_kernel_api

  ;; Log
  mov esi, str_done
  call log

  ;; Call start
  call start

  mov esi, str_exit
  call log

  mov eax, 0
  jmp shutdown


platform_panic:
panic:
  ;; Write an exit string
  mov esi, str_panic
  call log

  mov eax, 1
  jmp shutdown


  ;; Input character in CL
  ;; Destroys: EAX, EDX
write:
  jmp write_console


  ;; Input string in ESI
  ;; Destroys: EAX, ECX, EDX, ESI
log:
  mov cl, [esi]
  test cl, cl
  jz ret_simple
  call write
  inc esi
  jmp log


platform_allocate:
  mov eax, [esp+4]

  ;; Size in EAX
  ;; Destroys: ECX
  ;; Returns: EAX
allocate:
  dec eax
  or eax, 0x3
  inc eax
  mov ecx, eax
  mov eax, [heap_ptr]
  add ecx, eax
  mov [heap_ptr], ecx
  ret


str_platform_panic:
  db 'platform_panic'
  db 0
str_platform_allocate:
  db 'platform_allocate'
  db 0
str_platform_get_symbol:
  db 'platform_get_symbol'
  db 0

  ;; Initialize the symbols table with the "kernel API"
init_kernel_api:
  push 0
  push platform_panic
  push str_platform_panic
  call add_symbol
  add esp, 12

  push 1
  push platform_allocate
  push str_platform_allocate
  call add_symbol
  add esp, 12

  push 2
  push platform_get_symbol
  push str_platform_get_symbol
  call add_symbol
  add esp, 12

  ret


  ;; int platform_get_symbol(char *name, int *arity)
  ;; similar as find_symbol, but panic if it does not exist; retuns
  ;; the location and put the arity in *arity if arity is not null
platform_get_symbol:
  ;; Call find_symbol
  mov edx, [esp+4]
  call find_symbol

  ;; Panic if it does not exist
  cmp eax, 0
  je platform_panic

  ;; Save arity if required
  mov eax, [esp+8]
  cmp eax, 0
  je platform_get_symbol_ret
  mov [eax], edx

platform_get_symbol_ret:
  ;; Return the symbol location
  mov eax, ecx

  ret
