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

const FROM 20
const TO 0x64

ifun do_sum 2

fun main 0 {
  "The sum of numbers from " 1 platform_log ;
  FROM itoa 1 platform_log ;
  " to " 1 platform_log ;
  TO itoa 1 platform_log ;
  " is " 1 platform_log ;
  FROM TO do_sum itoa 1 platform_log ;
  "\n" 1 platform_log ;
}

fun do_sum 2 {
  $from
  $to
  @from 1 param = ;
  @to 0 param = ;

  $i
  $sum
  @i from = ;
  @sum 0 = ;
  while i to <= {
    @sum sum i + = ;
    @i i 1 + = ;
  }

  sum ret ;
}
