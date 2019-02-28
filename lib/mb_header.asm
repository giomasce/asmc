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

  bits 32
  org 0x100000

  MBMAGIC equ 0x1badb002
  ;; Set flags for alignment, memory map and load adds
  MBFLAGS equ 0x10003
  MBCHECKSUM equ 0x100000000 - MBMAGIC - MBFLAGS

  jmp entry

  align 4

  MBBEGIN equ $

  ;; Multiboot header
  dd MBMAGIC
  dd MBFLAGS
  dd MBCHECKSUM

  dd MBBEGIN
  dd 0x100000
  dd 0x0
  dd 0x0
  dd 0x100000
