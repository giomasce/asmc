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


;; This code is ported with small changes from setjmp.S in newlib,
;; which has the following copyright notice:

;; Copyright (C) 1991 DJ Delorie
;; All rights reserved.

;; Redistribution, modification, and use in source and binary forms is permitted
;; provided that the above copyright notice and following paragraph are
;; duplicated in all such forms.

;; This file is distributed WITHOUT ANY WARRANTY; without even the implied
;; warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.



  ;; int platform_setjmp(jmp_buf *env)
platform_setjmp:
  ;; Usual prologue
  push ebp
  mov ebp, esp

  ;; Use edi to point the jump buffer, after having saved its value
  push edi
  mov edi, [ebp+8]

  ;; Save the easy registers
  mov [edi], eax
  mov [edi+4], ebx
  mov [edi+8], ecx
  mov [edi+12], edx
  mov [edi+16], esi

  ;; Recover edi from the stack
  mov eax, [ebp+0xfffffffc]
  mov [edi+20], eax

  ;; Recover ebp from the stack
  mov eax, [ebp]
  mov [edi+24], eax

  ;; Save esp after having corrected it for the three push-es (two
  ;; explicit and one given by the function call)
  mov eax, esp
  add eax, 12
  mov [edi+28], eax

  ;; Equivalently, we could probably use this, which does not depend
  ;; on the number of explicit pushes
  ;; mov eax, ebp
  ;; add eax, 12
  ;; mov [edi+28], eax

  ;; Recover eip from the stack
  mov eax, [ebp+4]
  mov [edi+32], eax

  ;; Restore registers
  pop edi
  pop ebp

  ;; Return zero
  mov eax, 0
  ret


  ;; void platform_longjmp(jmp_buf *env, int status)
platform_longjmp:
  ;; Usual prologue
  push ebp
  mov ebp, esp

  ;; Use edi and eax for env and status
  mov edi, [ebp+8]
  mov eax, [ebp+12]
  mov [edi], eax

  ;; Restore stack
  mov ebp, [edi+24]
  mov esp, [edi+28]

  ;; Push eip for returning
  push [edi+32]

  ;; Restore all the other registers, except eax which is already
  ;; loaded, leaving edi as the last one
  mov eax, [edi]
  mov ebx, [edi+4]
  mov ecx, [edi+8]
  mov edx, [edi+12]
  mov esi, [edi+16]
  mov edi, [edi+20]

  ;; Return
  ret
