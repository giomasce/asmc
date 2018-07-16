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

fun realloc 2 {
  $ptr
  $newsize
  @ptr 0 param = ;
  @newsize 1 param = ;
  $size
  @size ptr _malloc_get_size = ;
  $newptr
  @newptr newsize malloc = ;
  $copysize
  @copysize size newsize min = ;
  copysize ptr newptr memcpy ;
  ptr free ;
  newptr ret ;
}

fun strdup 1 {
  $s
  @s 0 param = ;
  $len
  @len s strlen = ;
  $ptr
  @ptr len 1 + malloc = ;
  s ptr strcpy ;
  ptr ret ;
}
