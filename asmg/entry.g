# This file is part of asmc, a bootstrapping OS with minimal seed
# Copyright (C) 2018-2019 Giovanni Mascellani <gio@debian.org>
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

fun log 1 {
  0 param 1 platform_log ;
}

fun entry 0 {
  "Hello, G!\n" 1 log ;

  "Compiling main.g... " 1 log ;
  "main.g" platform_g_compile ;
  "done!\n" 1 log ;

  "Entering main program!\n" 1 platform_log ;
  0 "main" platform_get_symbol \0 ;
}
