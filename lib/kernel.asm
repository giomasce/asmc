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

open_files:
  resd 1

open_file_num:
  resd 1

write_mem_ptr:
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

str_init_heap_stack:
  db 'Initializing heap and stack... '
  db 0
str_init_files:
  db 'Initializing files table... '
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
  mov esi, str_init_heap_stack
  call log

  ;; Log
  mov esi, str_done
  call log

  ;; Log
  mov esi, str_init_files
  call log

  ;; Initialize file table
  mov DWORD [open_file_num], 0
  mov eax, FILE_RECORD_SIZE * MAX_OPEN_FILE_NUM
  call allocate
  mov [open_files], eax

  ;; Log
  mov esi, str_done
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

  call platform_exit

platform_exit:
  ;; Write an exit string
  mov esi, str_exit
  call log

  mov eax, 0
  jmp loop_forever


platform_panic:
  ;; Write an exit string
  mov esi, str_panic
  call log

  mov eax, 1
  jmp loop_forever


platform_write_char:
  ;; Switch depending on the requested file descriptor
  mov cl, [esp+8]

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


platform_log:
  push esi
  mov esi, [esp+12]
  call log
  pop esi
  ret


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


platform_open_file:
  push ebp
  mov ebp, esp
  push esi
  push edi

  ;; Find the file pointers
  mov ecx, [ebp+8]
  call walk_initrd

  ;; Find the new file record (stored in eax)
  mov ecx, [open_file_num]
  shl ecx, FILE_RECORD_SIZE_LOG
  add ecx, [open_files]

  ;; Set file pointers in the file record
  mov [ecx], eax
  mov [ecx+4], eax
  mov [ecx+8], edx

  ;; Return and increment the open file number
  mov eax, [open_file_num]
  add DWORD [open_file_num], 1

  pop edi
  pop esi
  pop ebp

  ret


platform_reset_file:
  ;; Find the file record
  mov eax, [esp+4]
  shl eax, FILE_RECORD_SIZE_LOG
  add eax, [open_files]

  ;; Reset it to the beginning
  mov ecx, [eax]
  mov [eax+4], ecx

  ret


platform_read_char:
  ;; Find the file record
  mov eax, [esp+4]
  shl eax, FILE_RECORD_SIZE_LOG
  add eax, [open_files]

  ;; Check if we are at the end
  mov ecx, [eax+4]
  cmp ecx, [eax+8]
  je platform_read_char_eof

  ;; Return a character and increment pointer
  mov edx, 0
  mov dl, [ecx]
  add DWORD [eax+4], 1
  mov eax, edx
  ret

platform_read_char_eof:
  ;; Return -1
  mov eax, 0xffffffff
  ret


str_platform_panic:
  db 'platform_panic'
  db 0
str_platform_exit:
  db 'platform_exit'
  db 0
str_platform_open_file:
  db 'platform_open_file'
  db 0
str_platform_read_char:
  db 'platform_read_char'
  db 0
str_platform_write_char:
  db 'platform_write_char'
  db 0
str_platform_reset_file:
  db 'platform_reset_file'
  db 0
str_platform_log:
  db 'platform_log'
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

  push 0
  push platform_exit
  push str_platform_exit
  call add_symbol
  add esp, 12

  push 1
  push platform_open_file
  push str_platform_open_file
  call add_symbol
  add esp, 12

  push 1
  push platform_read_char
  push str_platform_read_char
  call add_symbol
  add esp, 12

  push 2
  push platform_write_char
  push str_platform_write_char
  call add_symbol
  add esp, 12

  push 1
  push platform_reset_file
  push str_platform_reset_file
  call add_symbol
  add esp, 12

  push 2
  push platform_log
  push str_platform_log
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
  mov eax, [esp+4]
  mov ecx, [esp+8]
  push 0
  mov edx, esp
  push ecx
  push edx
  push eax
  call find_symbol
  add esp, 12

  ;; Panic if it does not exist
  cmp eax, 0
  je platform_panic

  ;; Return the symbol location
  pop eax

  ret
