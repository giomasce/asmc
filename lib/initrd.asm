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


  ;; filename in ECX
  ;; Destroys: ESI, EDI
  ;; Returns: EAX (begin), EDX (end)
walk_initrd:
  ;; Skip the header 'DISKFS  '
  mov edx, initrd+8

walk_initrd_loop:
  ;; Fail if at the end
  cmp BYTE [edx], 0
  je walk_initrd_fail

  ;; Compare the name with the target name (store in edi)
  mov esi, edx
  mov edi, ecx
  call strcmp2
  mov edi, eax

  ;; Advance by string length plus nine (jump over the terminator and the two pointers)
  mov esi, edx
  call strlen2
  lea edx, [edx+eax+9]

  ;; If the name is wrong, restart the cycle
  test edi, edi
  jnz walk_initrd_loop

  ;; Pointers are in network order, so we have to swap them
  mov eax, [edx-8]
  bswap eax
  add eax, initrd
  mov edx, [edx-4]
  bswap edx
  add edx, eax
  ret

walk_initrd_fail:
  ;; Set begin to zero and end to the actual end of initrd
  mov eax, [edx-8]
  bswap eax
  add eax, initrd
  mov edx, [edx-4]
  bswap edx
  add edx, eax
  xor eax, eax
  ret