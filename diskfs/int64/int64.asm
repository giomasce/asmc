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

i64_lnot:
  mov eax, [esp+4]
  mov ecx, [eax]
  or ecx, [eax+4]
  xor edx, edx
  mov [eax+4], edx
  test ecx, ecx
  sete dl
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
