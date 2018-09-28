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

  IDT_BASE equ 0x10000
  IDT_SIZE equ 0x800

empty_idt:
  mov ecx, IDT_SIZE
empty_idt_loop:
  cmp ecx, 0
  je empty_idt_ret
  mov eax, IDT_BASE
  add eax, ecx
  mov byte [eax], 0
  dec ecx
  jmp empty_idt_loop
empty_idt_ret:
  ret

  ;; entry id in EAX, target in EDX
fill_idt_entry:
  ;; Compute entry address
  shl eax, 3
  add eax, IDT_BASE

  ;; Offset
  mov [eax], dx
  shr edx, 16
  mov [eax+6], dx

  ;; Code segment selector
  mov word [eax+2], 0x8

  ;; Type attributes
  mov byte [eax+5], 10001111b

  ret

setup_idt:
  call empty_idt

  mov eax, 13
  mov edx, first_fault_handler
  call fill_idt_entry

  mov eax, 0x80
  mov edx, abort_handler
  call fill_idt_entry

  mov eax, 8
  mov edx, double_fault_handler
  call fill_idt_entry

  mov word [idt_size], IDT_SIZE
  dec word [idt_size]
  mov dword [idt_offset], IDT_BASE
  lidt [idt_desc]

  ret

  align 4

idt_desc:
idt_size:
  dw 0
idt_offset:
  dd 0

abort_handler:
  pusha

  mov esi, str_abort
  call print_string

  call dump_stack

  mov eax, [esp+32]
  call dump_code

  call error

first_fault_handler:
  pusha

  mov esi, str_first_fault
  call print_string

  call dump_stack

  mov eax, [esp+36]
  call dump_code

  call error

double_fault_handler:
  pusha

  mov esi, str_double_fault
  call print_string

  call dump_stack

  call error

dump_stack:
  mov ecx, 64
print_stack_loop:
  dec ecx
  mov al, [esp+ecx]
  push ecx
  call print_hex_char
  mov al, ' '
  call print_char
  pop ecx
  test ecx, 0x3
  jnz print_stack_test
  push ecx
  mov al, 0xa
  call print_char
  pop ecx
print_stack_test:
  cmp ecx, 0
  je print_stack_ret
  jmp print_stack_loop
print_stack_ret:
  ret

dump_code:
  mov ecx, 0
print_code_loop:
  cmp ecx, 32
  je print_code_ret
  push eax
  push ecx
  mov al, [eax+ecx]
  call print_hex_char
  mov al, ' '
  call print_char
  pop ecx
  pop eax
  inc ecx
  jmp print_code_loop
print_code_ret:
  mov al, 0xa
  call print_char
  ret

print_hex_nibble:
  and al, 0xf
  cmp al, 0xa
  jl print_hex_nibble_decimal
  add al, 'a' - 10
  jmp print_hex_nibble_print
print_hex_nibble_decimal:
  add al, '0'
print_hex_nibble_print:
  call print_char
  ret

print_hex_char:
  mov cl, al
  shr al, 4
  call print_hex_nibble
  mov al, cl
  call print_hex_nibble
  ret

str_abort:
  db 'ABORT!', 0xa, 0xd, 0
str_first_fault:
  db 'FIRST FAULT!', 0xa, 0xd, 0
str_double_fault:
  db 'Double fault detected!', 0xa, 0xd, 0
