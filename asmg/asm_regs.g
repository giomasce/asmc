# This file is part of asmc, a bootstrapping OS with minimal seed
# Copyright (C) 2018 Giovanni Mascellani <gio@debian.org>
# https://gitlab.com/giomasce/asmc

# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.

# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.

# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <https://www.gnu.org/licenses/>.

fun parse_register 1 {
  $reg
  @reg 0 param = ;

  if reg "al" strcmp_case 0 == { 0x10 ret ; }
  if reg "cl" strcmp_case 0 == { 0x11 ret ; }
  if reg "dl" strcmp_case 0 == { 0x12 ret ; }
  if reg "bl" strcmp_case 0 == { 0x13 ret ; }
  if reg "ah" strcmp_case 0 == { 0x14 ret ; }
  if reg "ch" strcmp_case 0 == { 0x15 ret ; }
  if reg "dh" strcmp_case 0 == { 0x16 ret ; }
  if reg "bh" strcmp_case 0 == { 0x17 ret ; }

  if reg "ax" strcmp_case 0 == { 0x20 ret ; }
  if reg "cx" strcmp_case 0 == { 0x21 ret ; }
  if reg "dx" strcmp_case 0 == { 0x22 ret ; }
  if reg "bx" strcmp_case 0 == { 0x23 ret ; }
  if reg "sp" strcmp_case 0 == { 0x24 ret ; }
  if reg "bp" strcmp_case 0 == { 0x25 ret ; }
  if reg "si" strcmp_case 0 == { 0x26 ret ; }
  if reg "di" strcmp_case 0 == { 0x27 ret ; }

  if reg "eax" strcmp_case 0 == { 0x30 ret ; }
  if reg "ecx" strcmp_case 0 == { 0x31 ret ; }
  if reg "edx" strcmp_case 0 == { 0x32 ret ; }
  if reg "ebx" strcmp_case 0 == { 0x33 ret ; }
  if reg "esp" strcmp_case 0 == { 0x34 ret ; }
  if reg "ebp" strcmp_case 0 == { 0x35 ret ; }
  if reg "esi" strcmp_case 0 == { 0x36 ret ; }
  if reg "edi" strcmp_case 0 == { 0x37 ret ; }

  if reg "cs" strcmp_case 0 == { 0x28 ret ; }
  if reg "ss" strcmp_case 0 == { 0x29 ret ; }
  if reg "ds" strcmp_case 0 == { 0x2a ret ; }
  if reg "es" strcmp_case 0 == { 0x2b ret ; }
  if reg "fs" strcmp_case 0 == { 0x2c ret ; }
  if reg "gs" strcmp_case 0 == { 0x2d ret ; }

  0xffffffff ret ;
}
