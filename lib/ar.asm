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

  SLASH equ 0x2f

  AR_BUF_SIZE equ 32

ar_buf:
  resb AR_BUF_SIZE


  ;; void walk_initrd(char *filename, void **begin, void **end)
  ;; Search the initrd for a file and return the file beginning and
  ;; end in RAM (undefined behaviour if the file does not exist)
walk_initrd:
  push ebp
  mov ebp, esp
  push esi
  push edi

  ;; Skip the header !<arch>\n (use esi for the current reading
  ;; position)
  mov esi, initrd
  add esi, 8

walk_initrd_loop:
  ;; Copy file name to buffer
  push 16
  push esi
  push ar_buf
  call memcpy
  add esp, 12

  ;; Substitute the first slash with a terminator
  push SLASH
  push ar_buf
  call find_char
  add esp, 8
  cmp eax, 0xffffffff
  je platform_panic
  add eax, ar_buf
  mov BYTE [eax], 0

  ;; Compare the name with the target name (store in edi)
  push ar_buf
  push DWORD [ebp+8]
  call strcmp
  add esp, 8
  mov edi, eax

  ;; Copy file size to the buffer
  add esi, 48
  push 10
  push esi
  push ar_buf
  call memcpy
  add esp, 12

  ;; Substitute the first space with a terminator
  push SPACE
  push ar_buf
  call find_char
  add esp, 8
  cmp eax, 0xffffffff
  je platform_panic
  add eax, ar_buf
  mov BYTE [eax], 0

  ;; Call atoi
  push ar_buf
  call atoi
  add esp, 4

  ;; Skip file header
  add esi, 12

  ;; If this is the file we want, return things
  cmp edi, 0
  je walk_initrd_ret_file

  ;; Skip file content
  add esi, eax

  ;; Realign to 2 bytes
  sub esi, 1
  or esi, 1
  add esi, 1

  jmp walk_initrd_loop

walk_initrd_ret_file:
  mov edx, [ebp+12]
  mov [edx], esi
  mov edx, [ebp+16]
  add esi, eax
  mov [edx], esi

  pop edi
  pop esi
  pop ebp
  ret
