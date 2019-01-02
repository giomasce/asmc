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

  ;; Easy conversions from 32 bits numbers
i64_from_32:
  mov ecx, [esp+8]
  mov eax, [esp+4]
  cdq
  mov [ecx], eax
  mov [ecx+4], edx
  ret

i64_from_u32:
  mov ecx, [esp+8]
  mov eax, [esp+4]
  xor edx, edx
  mov [ecx], eax
  mov [ecx+4], edx
  ret

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

i64_neg:
  mov eax, [esp+4]
  neg [eax]
  adc DWORD [eax+4], 0
  neg [eax+4]
  ret

  ;; Multiplication is a bit more complicated: first of all, we treat
  ;; the operation as unsigned, since we are going to retain only
  ;; the lower 64 bits, so signedness does not matter; suppose the
  ;; two operands are AB and CD (A is the lower dword of the first
  ;; operand, B is the upper dword of the first operand and so
  ;; on). Suppose that the unsigned multiplication of A and C gives
  ;; the result EF. Then the product of AB and CD is EG, where G =
  ;; F + A*D + B*C (in these last two multiplications the upper
  ;; dwords of the results are discarded; for this reason, we can
  ;; use the two operands form of imul).
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

  ;; Left shifts are done independently on the two dwords, except that
  ;; for the upper dword we have to shift in bits from the lower
  ;; dword using shld; if the shift count is 32 or more, we also
  ;; have to move the upper dword to the lower one, and then reset
  ;; the upper one (x86 architecture guarantees that shifts are
  ;; done modulo 32 anyway)
i64_shl:
  push ebx
  mov eax, [esp+12]
  mov ecx, [esp+8]
  mov ecx, [ecx]
  mov ebx, [eax]
  mov edx, [eax+4]
  shld edx, ebx, cl
  shl ebx, cl
  cmp cl, 32
  jb i64_shl_little
  mov edx, ebx
  xor ebx, ebx
i64_shl_little:
  mov [eax], ebx
  mov [eax+4], edx
  pop ebx
  ret

  ;; Logical right shift is similar to left shift; notice that lower
  ;; and upper dwords have to be inverted
i64_shr:
  push ebx
  mov eax, [esp+12]
  mov ecx, [esp+8]
  mov ecx, [ecx]
  mov ebx, [eax]
  mov edx, [eax+4]
  shrd ebx, edx, cl
  shr edx, cl
  cmp cl, 32
  jb i64_shr_little
  mov ebx, edx
  xor edx, edx
i64_shr_little:
  mov [eax], ebx
  mov [eax+4], edx
  pop ebx
  ret

  ;; Arithmetic right shift is similar to logic right shift, but when
  ;; the count is 32 or more the upper word has to be filled with
  ;; the sign, not with zero
i64_sar:
  push ebx
  mov eax, [esp+12]
  mov ecx, [esp+8]
  mov ecx, [ecx]
  mov ebx, [eax]
  mov edx, [eax+4]
  shrd ebx, edx, cl
  sar edx, cl
  cmp cl, 32
  jb i64_shr_little
  mov ebx, edx
  sar edx, 31
i64_sar_little:
  mov [eax], ebx
  mov [eax+4], edx
  pop ebx
  ret

  ;; Helpers for comparison functions
i64_ret_true:
  xor edx, edx
  mov [eax+4], edx
  inc edx
  mov [eax], edx
  ret

i64_ret_false:
  xor edx, edx
  mov [eax+4], edx
  mov [eax], edx
  ret

  ;; Comparison are many, but straightforward: first compare upper
  ;; dwords and, if needed, then compare lower dwords; leave address
  ;; of return value in EAX, so that i64_ret_true and i64_ret_false
  ;; do the right thing
i64_eq:
  mov eax, [esp+8]
  mov edx, [esp+4]
  mov ecx, [eax+4]
  cmp ecx, [edx+4]
  jne i64_ret_false
  mov ecx, [eax]
  cmp ecx, [edx]
  jne i64_ret_false
  jmp i64_ret_true

i64_neq:
  mov eax, [esp+8]
  mov edx, [esp+4]
  mov ecx, [eax+4]
  cmp ecx, [edx+4]
  jne i64_ret_true
  mov ecx, [eax]
  cmp ecx, [edx]
  jne i64_ret_true
  jmp i64_ret_false

i64_le:
  mov eax, [esp+8]
  mov edx, [esp+4]
  mov ecx, [eax+4]
  cmp ecx, [edx+4]
  jg i64_ret_false
  jl i64_ret_true
  mov ecx, [eax]
  cmp ecx, [edx]
  ja i64_ret_false
  jmp i64_ret_true

i64_ule:
  mov eax, [esp+8]
  mov edx, [esp+4]
  mov ecx, [eax+4]
  cmp ecx, [edx+4]
  ja i64_ret_false
  jb i64_ret_true
  mov ecx, [eax]
  cmp ecx, [edx]
  ja i64_ret_false
  jmp i64_ret_true

i64_l:
  mov eax, [esp+8]
  mov edx, [esp+4]
  mov ecx, [eax+4]
  cmp ecx, [edx+4]
  jg i64_ret_false
  jl i64_ret_true
  mov ecx, [eax]
  cmp ecx, [edx]
  jae i64_ret_false
  jmp i64_ret_true

i64_ul:
  mov eax, [esp+8]
  mov edx, [esp+4]
  mov ecx, [eax+4]
  cmp ecx, [edx+4]
  ja i64_ret_false
  jb i64_ret_true
  mov ecx, [eax]
  cmp ecx, [edx]
  jae i64_ret_false
  jmp i64_ret_true

i64_ge:
  mov eax, [esp+8]
  mov edx, [esp+4]
  mov ecx, [eax+4]
  cmp ecx, [edx+4]
  jg i64_ret_true
  jl i64_ret_false
  mov ecx, [eax]
  cmp ecx, [edx]
  jae i64_ret_true
  jmp i64_ret_false

i64_uge:
  mov eax, [esp+8]
  mov edx, [esp+4]
  mov ecx, [eax+4]
  cmp ecx, [edx+4]
  ja i64_ret_true
  jb i64_ret_false
  mov ecx, [eax]
  cmp ecx, [edx]
  jae i64_ret_true
  jmp i64_ret_false

i64_g:
  mov eax, [esp+8]
  mov edx, [esp+4]
  mov ecx, [eax+4]
  cmp ecx, [edx+4]
  jg i64_ret_true
  jl i64_ret_false
  mov ecx, [eax]
  cmp ecx, [edx]
  ja i64_ret_true
  jmp i64_ret_false

i64_ug:
  mov eax, [esp+8]
  mov edx, [esp+4]
  mov ecx, [eax+4]
  cmp ecx, [edx+4]
  ja i64_ret_true
  jb i64_ret_false
  mov ecx, [eax]
  cmp ecx, [edx]
  ja i64_ret_true
  jmp i64_ret_false
