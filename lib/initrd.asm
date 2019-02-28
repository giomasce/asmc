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


  ;; More or less as walk_initrd, but just find the end; do not use
  ;; stack
find_initrd_end:
  ;; Skip header
  mov eax, initrd
  add eax, 8

find_initrd_end_loop:
  ;; Finish if we have found the empty entry
  cmp BYTE [eax], 0
  je find_initrd_end_ret

find_initrd_end_loop2:
  ;; Discard a null-terminated string
  cmp BYTE [eax], 0
  je find_initrd_end_loop2_done
  add eax, 1
  jmp find_initrd_end_loop2

find_initrd_end_loop2_done:
  ;; Discard the terminator and the two pointers, then restart
  add eax, 9
  jmp find_initrd_end_loop

find_initrd_end_ret:
  mov ecx, [eax-8]
  bswap ecx
  add ecx, initrd
  mov eax, [eax-4]
  bswap eax
  add eax, ecx
  ret


  ;; void walk_initrd(char *filename, void **begin, void **end)
walk_initrd:
  push ebp
  mov ebp, esp
  push esi
  push edi

  ;; Skip the header 'DISKFS  ' (use esi for the current reading
  ;; position)
  mov esi, initrd
  add esi, 8

walk_initrd_loop:
  ;; Fail if at the end
  cmp BYTE [esi], 0
  je walk_initrd_fail

  ;; Compare the name with the target name (store in edi)
  push esi
  push DWORD [ebp+8]
  call strcmp
  add esp, 8
  mov edi, eax

  ;; Advance by string length plus one
  push esi
  call strlen
  add esp, 4
  add esi, eax
  add esi, 1

  ;; If the name is correct, return
  test edi, edi
  jz walk_initrd_success

  ;; If not skip the two numbers and restart
  add esi, 8
  jmp walk_initrd_loop

walk_initrd_success:
  ;; Compute begin and end
  mov edx, [ebp+12]
  mov ecx, [esi]
  bswap ecx
  add ecx, initrd
  mov [edx], ecx
  mov edx, [ebp+16]
  mov eax, [esi+4]
  bswap eax
  add ecx, eax
  mov [edx], ecx

  pop edi
  pop esi
  pop ebp
  ret

walk_initrd_fail:
  ;; Set begin and end to zero
  xor eax, eax
  mov edx, [ebp+12]
  mov [edx], eax
  mov edx, [ebp+16]
  mov [edx], eax

  pop edi
  pop esi
  pop ebp
  ret
