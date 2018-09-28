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

pmc_supported:
  dd 0


query_pmc:
  ;; Call CPUID
  mov eax, 0xa
  cpuid
  mov edx, pmc_supported
  cmp al, 2
  jb query_pmc_ret_false
  mov DWORD [edx], 1

  ;; Log
  push str_pmc_avail
  push 1
  call platform_log
  add esp, 8

  ret

query_pmc_ret_false:
  mov DWORD [edx], 0

  ;; Log
  push str_pmc_unavail
  push 1
  call platform_log
  add esp, 8

  ret


enable_pmc:
  ;; Query PMC availability and return if they are not available
  call query_pmc
  mov edx, pmc_supported
  cmp DWORD [edx], 0
  je enable_pmc_ret

  ;; Enable retired instruction counder (only PMC supported so far)
  mov ecx, 0x38d
  rdmsr
  or eax, 0x1
  mov ecx, 0x38d
  wrmsr

enable_pmc_ret:
  ret


read_ret_instr:
  ;; Return 0 is PMC are not available
  mov edx, pmc_supported
  cmp DWORD [edx], 0
  je read_ret_instr_ret0

  ;; Read retiret instruction counter
  mov ecx, 0x40000000
  rdpmc
  ret

read_ret_instr_ret0:
  mov eax, 0
  mov edx, 0
  ret


str_pmc_avail:
  db 'Performance counters are available and enabled!'
  db NEWLINE
  db 0
str_pmc_unavail:
  db 'Performance counters are not available...'
  db NEWLINE
  db 0
