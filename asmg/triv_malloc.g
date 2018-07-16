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

fun malloc 1 {
  $size
  @size 0 param = ;
  $alloc_size
  # Add space for the length
  @alloc_size size 4 + = ;
  # Make it a multiple of 4
  @alloc_size alloc_size 1 - 0x3 | 1 + = ;
  $ptr
  @ptr alloc_size platform_allocate = ;
  ptr 1024 1024 * 100 * < "too much alloc" assert_msg ;
  ptr size = ;
  ptr 4 + ret ;
}

fun free 1 {
}

fun _malloc_get_size 1 {
  $ptr
  @ptr 0 param = ;
  $size
  @size ptr 4 - ** = ;
  size ret ;
}

fun malloc_stats 0 {
}
