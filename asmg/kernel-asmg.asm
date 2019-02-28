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

str_platform_setjmp:
  db 'platform_setjmp'
  db 0
str_platform_longjmp:
  db 'platform_longjmp'
  db 0

str_init_compile_entry:
  db 'Will now compile entry.g...'
  db NEWLINE
  db 0
str_init_launch_entry:
  db 'Will now call entry!'
  db NEWLINE
  db 0

str_entry_g:
  db 'entry.g'
  db 0
str_entry:
  db 'entry'
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

  ;; Add some asmg-specific platform_* calls
  push 1
  push platform_g_compile
  push str_platform_g_compile
  call add_symbol
  add esp, 12
  push 1
  push platform_setjmp
  push str_platform_setjmp
  call add_symbol
  add esp, 12
  push 2
  push platform_longjmp
  push str_platform_longjmp
  call add_symbol
  add esp, 12

  ;; Log
  push str_init_compile_entry
  push 1
  call platform_log
  add esp, 8

  ;; Compile entry.g
  push str_entry_g
  call platform_g_compile
  add esp, 4

  ;; Log
  push str_init_launch_entry
  push 1
  call platform_log
  add esp, 8

  ;; Set EBP to zero, so that stack traces originating from the G code
  ;; are cut
  push ebp
  mov ebp, 0

  ;; Enable PMC
  call enable_pmc

  ;; Call entry
  push 0
  push str_entry
  call platform_get_symbol
  add esp, 8
  call eax

  pop ebp

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
  imul DWORD [esp+4]
  ret

str_over:
  db '/'
  db 0
over:
  mov eax, [esp+8]
  cdq
  idiv DWORD [esp+4]
  ret

str_mod:
  db '%'
  db 0
mod:
  mov eax, [esp+8]
  cdq
  idiv DWORD [esp+4]
  mov eax, edx
  ret

str_uover:
  db '/u'
  db 0
uover:
  mov edx, 0
  mov eax, [esp+8]
  div DWORD [esp+4]
  ret

str_umod:
  db '%u'
  db 0
umod:
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

str_lu:
  db '<u'
  db 0
lu:
  mov eax, 1
  mov ecx, [esp+8]
  cmp ecx, [esp+4]
  jb ret
  mov eax, 0
  ret

str_leu:
  db '<=u'
  db 0
leu:
  mov eax, 1
  mov ecx, [esp+8]
  cmp ecx, [esp+4]
  jbe ret
  mov eax, 0
  ret

str_gu:
  db '>u'
  db 0
gu:
  mov eax, 1
  mov ecx, [esp+8]
  cmp ecx, [esp+4]
  ja ret
  mov eax, 0
  ret

str_geu:
  db '>=u'
  db 0
geu:
  mov eax, 1
  mov ecx, [esp+8]
  cmp ecx, [esp+4]
  jae ret
  mov eax, 0
  ret

str_shl:
  db '<<'
  db 0
shl:
  mov ecx, [esp+4]
  mov eax, [esp+8]
  shl eax, cl
  ret

str_shr:
  db '>>'
  db 0
shr:
  mov ecx, [esp+4]
  mov eax, [esp+8]
  shr eax, cl
  ret

str_shlu:
  db '<<u'
  db 0
shlu:
  mov ecx, [esp+4]
  mov eax, [esp+8]
  sal eax, cl
  ret

str_shru:
  db '>>u'
  db 0
shru:
  mov ecx, [esp+4]
  mov eax, [esp+8]
  sar eax, cl
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

str_xor:
  db '^'
  db 0
xor:
  mov eax, [esp+8]
  xor eax, [esp+4]
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

str_ind:
  db 'ind'
  db 0
ind:
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

str_outd:
  db 'outd'
  db 0
outd:
  mov eax, [esp+4]
  mov edx, [esp+8]
  out dx, eax
  ret

str_itoa:
  db 'itoa'
  db 0

str_frame_ptr:
  db '__frame_ptr'
  db 0
frame_ptr:
  mov eax, ebp
  ret

str_max_symbol_name_len:
  db '__max_symbol_name_len'
  db 0
max_symbol_name_len:
  mov eax, MAX_SYMBOL_NAME_LEN
  ret

str_symbol_table_len:
  db '__symbol_table_len'
  db 0
symbol_table_len:
  mov eax, SYMBOL_TABLE_LEN
  ret

str_symbol_num:
  db '__symbol_num'
  db 0
symbol_num_func:
  mov eax, symbol_num
  mov eax, [eax]
  ret

str_symbol_names:
  db '__symbol_names'
  db 0
symbol_names_func:
  mov eax, symbol_names_ptr
  mov eax, [eax]
  ret

str_symbol_locs:
  db '__symbol_locs'
  db 0
symbol_locs_func:
  mov eax, symbol_locs_ptr
  mov eax, [eax]
  ret

str_symbol_arities:
  db '__symbol_arities'
  db 0
symbol_arities_func:
  mov eax, symbol_arities_ptr
  mov eax, [eax]
  ret

str_ret_instr:
  db '__ret_instr'
  db 0
ret_instr:
  call read_ret_instr
  ret


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
  push uover
  push str_uover
  call add_symbol
  add esp, 12

  push 2
  push umod
  push str_umod
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
  push lu
  push str_lu
  call add_symbol
  add esp, 12

  push 2
  push leu
  push str_leu
  call add_symbol
  add esp, 12

  push 2
  push gu
  push str_gu
  call add_symbol
  add esp, 12

  push 2
  push geu
  push str_geu
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
  push shlu
  push str_shlu
  call add_symbol
  add esp, 12

  push 2
  push shru
  push str_shru
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

  push 2
  push xor
  push str_xor
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
  push ind
  push str_ind
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
  push outd
  push str_outd
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

  push 0
  push frame_ptr
  push str_frame_ptr
  call add_symbol
  add esp, 12

  push 0
  push max_symbol_name_len
  push str_max_symbol_name_len
  call add_symbol
  add esp, 12

  push 0
  push symbol_table_len
  push str_symbol_table_len
  call add_symbol
  add esp, 12

  push 0
  push symbol_num_func
  push str_symbol_num
  call add_symbol
  add esp, 12

  push 0
  push symbol_names_func
  push str_symbol_names
  call add_symbol
  add esp, 12

  push 0
  push symbol_locs_func
  push str_symbol_locs
  call add_symbol
  add esp, 12

  push 0
  push symbol_arities_func
  push str_symbol_arities
  call add_symbol
  add esp, 12

  push 0
  push ret_instr
  push str_ret_instr
  call add_symbol
  add esp, 12

  ret
