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

str_helloasm:
  db 'Hello, ASM!'
  db 0xa
  db 0

str_atapio_asm:
  db 'atapio.asm'
  db 0
str_atapio_test_asm:
  db 'atapio_test.asm'
  db 0
str_atapio_test:
  db 'atapio_test'
  db 0

main:
  ;; Greetings!
  push str_helloasm
  push 1
  call platform_log
  add esp, 8

  ;; Compile the ATA PIO driver
  push str_atapio_asm
  call platform_assemble
  add esp, 4

  ;; Compile the ATA PIO test
  push str_atapio_test_asm
  call platform_assemble
  add esp, 4

  ;; Call atapio_test
  push 0
  push str_atapio_test
  call platform_get_symbol
  add esp, 8
  call eax

  ret
