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

str_platform_g_compile:
  db 'platform_g_compile'
  db 0

str_init_compile_main:
  db 'Will now compile main.g...'
  db NEWLINE
  db 0
str_init_launch_main:
  db 'Will now call main!'
  db NEWLINE
  db 0

str_main_g:
  db 'main.g'
  db 0
str_main:
  db 'main'
  db 0


  ;; void platform_g_compile(char *filename)
platform_g_compile:
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
  push 0
  push edx
  push 0
  push eax
  call compile
  add esp, 16

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

  ;; Discard temporary labels
  call discard_temp_labels

  ret


discard_temp_labels:
  push esi
  push edi
  push ebx

  ;; Use esi for the source index and edi for the dst index
  mov esi, 0
  mov edi, 0

discard_temp_labels_loop:
  ;; Check for termination
  mov eax, symbol_num
  cmp [eax], esi
  je discard_temp_labels_end

  ;; Check if the symbol is a temp label
  mov ecx, symbol_names_ptr
  mov ecx, [ecx]
  mov eax, MAX_SYMBOL_NAME_LEN
  mul esi
  add eax, ecx
  cmp BYTE [eax], DOT
  je discard_temp_label_loop_end

  ;; If the two pointers are equal, do nothing
  cmp esi, edi
  je discard_temp_label_update_dest

  ;; Copy name
  mov ebx, eax
  mov eax, MAX_SYMBOL_NAME_LEN
  mul edi
  add eax, ecx
  push ebx
  push eax
  call strcpy
  add esp, 8

  ;; Copy location
  mov ecx, symbol_locs_ptr
  mov ecx, [ecx]
  mov eax, 4
  mul esi
  add eax, ecx
  mov ebx, eax
  mov eax, 4
  mul edi
  add eax, ecx
  mov edx, [ebx]
  mov [eax], edx

  ;; Copy arity
  mov ecx, symbol_arities_ptr
  mov ecx, [ecx]
  mov eax, 4
  mul esi
  add eax, ecx
  mov ebx, eax
  mov eax, 4
  mul edi
  add eax, ecx
  mov edx, [ebx]
  mov [eax], edx

discard_temp_label_update_dest:
  add edi, 1

discard_temp_label_loop_end:
  ;; Increment reading pointer and reloop
  add esi, 1
  jmp discard_temp_labels_loop

discard_temp_labels_end:
  ;; Save the new length
  mov eax, symbol_num
  mov [eax], edi

  pop ebx
  pop edi
  pop esi
  ret


start:
  ;; Init compiler
  call init_g_compiler
  call init_g_operations
  push 1
  push platform_g_compile
  push str_platform_g_compile
  call add_symbol
  add esp, 12

  ;; Log
  push str_init_compile_main
  push 1
  call platform_log
  add esp, 8

  ;; Assemble main.asm
  push str_main_g
  call platform_g_compile
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


ret:
  ret

str_equal:
  db '='
  db 0
equal:
  mov eax, [esp+4]
  mov ecx, [esp+8]
  mov [ecx], eax
  ret

str_equalc:
  db '=c'
  db 0
equalc:
  mov eax, [esp+4]
  mov ecx, [esp+8]
  mov [ecx], al
  ret

str_param:
  db 'param'
  db 0
param:
  mov eax, [esp+4]
  mov edx, 4
  mul edx
  add eax, 8
  add eax, ebp
  mov eax, [eax]
  ret

str_plus:
  db '+'
  db 0
plus:
  mov eax, [esp+8]
  add eax, [esp+4]
  ret

str_minus:
  db '-'
  db 0
minus:
  mov eax, [esp+8]
  sub eax, [esp+4]
  ret

str_un_minus:
  db '--'
  db 0
un_minus:
  mov eax, [esp+8]
  neg eax
  ret

str_times:
  db '*'
  db 0
times_op:
  mov eax, [esp+8]
  mul DWORD [esp+4]
  ret

str_over:
  db '/'
  db 0
over:
  mov edx, 0
  mov eax, [esp+8]
  div DWORD [esp+4]
  ret

str_mod:
  db '%'
  db 0
mod:
  mov edx, 0
  mov eax, [esp+8]
  div DWORD [esp+4]
  mov eax, edx
  ret

str_eq:
  db '=='
  db 0
eq:
  mov eax, 1
  mov ecx, [esp+8]
  cmp ecx, [esp+4]
  je ret
  mov eax, 0
  ret

str_neq:
  db '!='
  db 0
neq:
  mov eax, 1
  mov ecx, [esp+8]
  cmp ecx, [esp+4]
  jne ret
  mov eax, 0
  ret

str_l:
  db '<'
  db 0
l:
  mov eax, 1
  mov ecx, [esp+8]
  cmp ecx, [esp+4]
  jl ret
  mov eax, 0
  ret

str_le:
  db '<='
  db 0
le:
  mov eax, 1
  mov ecx, [esp+8]
  cmp ecx, [esp+4]
  jle ret
  mov eax, 0
  ret

str_g:
  db '>'
  db 0
g:
  mov eax, 1
  mov ecx, [esp+8]
  cmp ecx, [esp+4]
  jg ret
  mov eax, 0
  ret

str_ge:
  db '>='
  db 0
ge:
  mov eax, 1
  mov ecx, [esp+8]
  cmp ecx, [esp+4]
  jge ret
  mov eax, 0
  ret

str_shl:
  db '<<'
  db 0
shl:
  mov ecx, [esp+4]
  mov eax, [esp+8]
  ;; shl eax, cl
  db 0xd3
  db 0xe0
  ret

str_shr:
  db '>>'
  db 0
shr:
  mov ecx, [esp+4]
  mov eax, [esp+8]
  ;; shr eax, cl
  db 0xd3
  db 0xe8
  ret

str_and:
  db '&'
  db 0
and:
  mov eax, [esp+8]
  and eax, [esp+4]
  ret

str_or:
  db '|'
  db 0
or:
  mov eax, [esp+8]
  or eax, [esp+4]
  ret

str_not:
  db '~'
  db 0
not:
  mov eax, [esp+4]
  not eax
  ret

str_land:
  db '&&'
  db 0
land:
  mov eax, 0
  cmp DWORD [esp+8], 0
  je ret
  cmp DWORD [esp+4], 0
  je ret
  mov eax, 1
  ret

str_lor:
  db '||'
  db 0
lor:
  mov eax, 1
  cmp DWORD [esp+8], 0
  jne ret
  cmp DWORD [esp+4], 0
  jne ret
  mov eax, 0
  ret

str_lnot:
  db '!'
  db 0
lnot:
  mov eax, 0
  cmp DWORD [esp+4], 0
  jne ret
  mov eax, 1
  ret

str_deref:
  db '**'
  db 0
deref:
  mov eax, [esp+4]
  mov eax, [eax]
  ret

str_derefc:
  db '**c'
  db 0
derefc:
  mov edx, [esp+4]
  mov eax, 0
  mov al, [edx]
  ret

str_inb:
  db 'inb'
  db 0
inb:
  mov edx, [esp+4]
  mov eax, 0
  in al, dx
  ret

str_inw:
  db 'inw'
  db 0
inw:
  mov edx, [esp+4]
  mov eax, 0
  in ax, dx
  ret

str_inq:
  db 'inq'
  db 0
inq:
  mov edx, [esp+4]
  mov eax, 0
  in eax, dx
  ret

str_outb:
  db 'outb'
  db 0
outb:
  mov eax, [esp+4]
  mov edx, [esp+8]
  out dx, al
  ret

str_outw:
  db 'outw'
  db 0
outw:
  mov eax, [esp+4]
  mov edx, [esp+8]
  out dx, ax
  ret

str_outq:
  db 'outq'
  db 0
outq:
  mov eax, [esp+4]
  mov edx, [esp+8]
  out dx, eax
  ret

str_itoa:
  db 'itoa'
  db 0
str_strcmp:
  db 'strcmp'
  db 0
str_strcpy:
  db 'strcpy'
  db 0
str_memcpy:
  db 'memcpy'
  db 0
str_strlen:
  db 'strlen'
  db 0


init_g_operations:
  push 2
  push equal
  push str_equal
  call add_symbol
  add esp, 12

  push 2
  push equalc
  push str_equalc
  call add_symbol
  add esp, 12

  push 1
  push param
  push str_param
  call add_symbol
  add esp, 12

  push 2
  push plus
  push str_plus
  call add_symbol
  add esp, 12

  push 2
  push minus
  push str_minus
  call add_symbol
  add esp, 12

  push 1
  push un_minus
  push str_un_minus
  call add_symbol
  add esp, 12

  push 2
  push times_op
  push str_times
  call add_symbol
  add esp, 12

  push 2
  push over
  push str_over
  call add_symbol
  add esp, 12

  push 2
  push mod
  push str_mod
  call add_symbol
  add esp, 12

  push 2
  push eq
  push str_eq
  call add_symbol
  add esp, 12

  push 2
  push neq
  push str_neq
  call add_symbol
  add esp, 12

  push 2
  push l
  push str_l
  call add_symbol
  add esp, 12

  push 2
  push le
  push str_le
  call add_symbol
  add esp, 12

  push 2
  push g
  push str_g
  call add_symbol
  add esp, 12

  push 2
  push ge
  push str_ge
  call add_symbol
  add esp, 12

  push 2
  push shl
  push str_shl
  call add_symbol
  add esp, 12

  push 2
  push shr
  push str_shr
  call add_symbol
  add esp, 12

  push 2
  push and
  push str_and
  call add_symbol
  add esp, 12

  push 2
  push or
  push str_or
  call add_symbol
  add esp, 12

  push 1
  push not
  push str_not
  call add_symbol
  add esp, 12

  push 2
  push land
  push str_land
  call add_symbol
  add esp, 12

  push 2
  push lor
  push str_lor
  call add_symbol
  add esp, 12

  push 1
  push lnot
  push str_lnot
  call add_symbol
  add esp, 12

  push 1
  push inb
  push str_inb
  call add_symbol
  add esp, 12

  push 1
  push inw
  push str_inw
  call add_symbol
  add esp, 12

  push 1
  push inq
  push str_inq
  call add_symbol
  add esp, 12

  push 2
  push outb
  push str_outb
  call add_symbol
  add esp, 12

  push 2
  push outw
  push str_outw
  call add_symbol
  add esp, 12

  push 2
  push outq
  push str_outq
  call add_symbol
  add esp, 12

  push 1
  push deref
  push str_deref
  call add_symbol
  add esp, 12

  push 1
  push derefc
  push str_derefc
  call add_symbol
  add esp, 12

  push 1
  push itoa
  push str_itoa
  call add_symbol
  add esp, 12

  push 2
  push strcmp
  push str_strcmp
  call add_symbol
  add esp, 12

  push 2
  push strcpy
  push str_strcpy
  call add_symbol
  add esp, 12

  push 3
  push memcpy
  push str_memcpy
  call add_symbol
  add esp, 12

  push 1
  push strlen
  push str_strlen
  call add_symbol
  add esp, 12

  ret
