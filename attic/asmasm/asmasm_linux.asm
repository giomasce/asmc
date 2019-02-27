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

  extern platform_panic
  extern platform_exit
  extern platform_open_file
  extern platform_reset_file
  extern platform_read_char
  extern platform_write_char
  extern platform_log
  extern platform_allocate

  section .data

  global main
main:
  ;; Init everything
  call init_symbols
  call init_assembler

  ;; Open input file
  mov eax, [esp+8]
  add eax, 4
  mov eax, [eax]
  push eax
  call platform_open_file
  add esp, 4

  ;; Call assemble
  push 0x100000
  push 1
  push eax
  call assemble
  add esp, 12

  mov eax, 0
  ret
