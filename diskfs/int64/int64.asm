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

  ;; Bitwise operations are pretty straightforward
i64_not:
  mov eax, [esp+4]
  not DWORD [eax]
  not DWORD [eax+4]
  ret

i64_and:
  mov eax, [esp+8]
  mov ecx, [esp+4]
  mov edx, [ecx]
  and [eax], edx
  mov edx, [ecx+4]
  and [eax+4], edx
  ret

i64_or:
  mov eax, [esp+8]
  mov ecx, [esp+4]
  mov edx, [ecx]
  or [eax], edx
  mov edx, [ecx+4]
  or [eax+4], edx
  ret

i64_xor:
  mov eax, [esp+8]
  mov ecx, [esp+4]
  mov edx, [ecx]
  xor [eax], edx
  mov edx, [ecx+4]
  xor [eax+4], edx
  ret

  ;; For logical operations, the complicated part is normalizing input
  ;; values: this is done by or-ing the two dwords together, then
  ;; applying test, sete and movzx on the result; after that,
  ;; logical operations can be done bitwise
i64_lnot:
  mov eax, [esp+4]
  mov ecx, [eax]
  or ecx, [eax+4]
  mov [eax+4], edx
  test ecx, ecx
  sete dl
  movzx edx, dl
  mov [eax], edx
  ret

i64_land:
  mov ecx, [esp+4]
  mov edx, [ecx]
  or edx, [ecx+4]
  test edx, edx
  setne dl
  movzx edx, dl
  mov eax, [esp+8]
  mov ecx, [eax]
  or ecx, [eax+4]
  test ecx, ecx
  setne cl
  movzx ecx, cl
  and ecx, edx
  xor edx, edx
  mov [eax], ecx
  mov [eax+4], edx
  ret

i64_lor:
  mov ecx, [esp+4]
  mov edx, [ecx]
  or edx, [ecx+4]
  test edx, edx
  setne dl
  movzx edx, dl
  mov eax, [esp+8]
  mov ecx, [eax]
  or ecx, [eax+4]
  test ecx, ecx
  setne cl
  movzx ecx, cl
  or ecx, edx
  xor edx, edx
  mov [eax], ecx
  mov [eax+4], edx
  ret

  ;; First we add the lower dwords, then add with carry the upper dwords
i64_add:
  mov eax, [esp+4]
  mov ecx, [eax]
  mov edx, [eax+4]
  mov eax, [esp+8]
  add [eax], ecx
  adc [eax+4], edx
  ret

  ;; First we subtract the lower dwords, then subtract with borrow the upper dwords
i64_sub:
  mov eax, [esp+4]
  mov ecx, [eax]
  mov edx, [eax+4]
  mov eax, [esp+8]
  sub [eax], ecx
  sbb [eax+4], edx
  ret

i64_mul:
  push ebx
  push esi
  mov ecx, [esp+12]
  mov ebx, [esp+16]
  mov eax, [ecx]
  mul DWORD [ebx]
  mov esi, eax
  mov eax, [ecx]
  mov ecx, [ecx+4]
  imul eax, [ebx+4]
  imul ecx, [ebx]
  add edx, eax
  add edx, ecx
  mov [ebx], esi
  mov [ebx+4], edx
  pop esi
  pop ebx
  ret
