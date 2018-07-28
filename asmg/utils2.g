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

fun append_to_str 2 {
  $s1
  $s2
  @s1 0 param = ;
  @s2 1 param = ;
  $len1
  $len2
  @len1 s1 strlen = ;
  @len2 s2 strlen = ;
  $newlen
  @newlen len1 len2 + 1 + = ;
  $news
  @news newlen s2 realloc = ;
  s1 news len2 + strcpy ;
  news ret ;
}

fun prepend_to_str 2 {
  $s1
  $s2
  @s1 0 param = ;
  @s2 1 param = ;
  $len1
  $len2
  @len1 s1 strlen = ;
  @len2 s2 strlen = ;
  $newlen
  @newlen len1 len2 + 1 + = ;
  $news
  @news newlen malloc = ;
  s1 news strcpy ;
  s2 news len1 + strcpy ;
  s2 free ;
  news ret ;
}

fun free_vect_of_ptrs 1 {
  $vect
  @vect 0 param = ;
  $i
  @i 0 = ;
  #"Freeing vector of length " 1 platform_log ;
  #vect vector_size itoa 1 platform_log ;
  #"\n" 1 platform_log ;
  while i vect vector_size < {
    #i itoa 1 platform_log ;
    #" " 1 platform_log ;
    vect i vector_at free ;
    @i i 1 + = ;
  }
  vect vector_destroy ;
}

fun dup_vect_of_ptrs 1 {
  $vect
  @vect 0 param = ;
  $newvect
  @newvect 4 vector_init = ;
  $i
  @i 0 = ;
  while i vect vector_size < {
    newvect vect i vector_at strdup vector_push_back ;
    @i i 1 + = ;
  }
  newvect ret ;
}
