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

str_check:
  db 'CHECK'
  db 0

debug_check:
  push eax
  push ecx
  push edx

  ;; Log
  push str_check
  push 1
  call platform_log
  add esp, 8

  pop edx
  pop ecx
  pop eax
  ret


debug_log:
  push ebp
  mov ebp, esp
  push eax
  push ecx
  push edx

  ;; Log
  push DWORD [ebp+8]
  push 1
  call platform_log
  add esp, 8

  pop edx
  pop ecx
  pop eax
  pop ebp
  ret


debug_log_itoa:
  push ebp
  mov ebp, esp
  push eax
  push ecx
  push edx

  ;; Itoa
  push DWORD [ebp+8]
  call itoa
  add esp, 4

  ;; Log
  push eax
  push 1
  call platform_log
  add esp, 8

  pop edx
  pop ecx
  pop eax
  pop ebp
  ret
