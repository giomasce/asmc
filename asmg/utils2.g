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

fun cmp_vect_of_ptrs 2 {
  $v1
  $v2
  @v1 1 param = ;
  @v2 0 param = ;

  if v1 vector_size v2 vector_size != {
    0 ret ;
  }
  $i
  @i 0 = ;
  while i v1 vector_size < {
    if v1 i vector_at v2 i vector_at strcmp 0 != {
      0 ret ;
    }
    @i i 1 + = ;
  }
  1 ret ;
}

$ext_symbols

fun resolve_symbol_ext_closure 3 {
  $ctx
  $key
  $value
  @ctx 2 param = ;
  @key 1 param = ;
  @value 0 param = ;

  $target_value
  $best_key
  $best_value
  @target_value ctx 8 + ** = ;
  @best_key ctx 4 + ** = ;
  @best_value ctx ** = ;

  if value target_value <= {
    if best_value value < {
      ctx 4 + key = ;
      ctx value = ;
    }
  }
}

fun resolve_symbol_ext 3 {
  $loc
  $nameptr
  $offptr
  @loc 2 param = ;
  @nameptr 1 param = ;
  @offptr 0 param = ;

  $target_value
  $best_key
  $best_value
  @target_value loc = ;
  @best_key 0 = ;
  @best_value 0 = ;

  ext_symbols @resolve_symbol_ext_closure @best_value map_foreach ;

  nameptr best_key = ;
  offptr target_value best_value - = ;

  0 best_value != ret ;
}

fun resolve_symbol_add 2 {
  $name
  $loc
  @name 1 param = ;
  @loc 0 param = ;

  ext_symbols name loc map_set ;
}

fun init_resolve_symbol_ext 0 {
  @ext_symbols map_init = ;
  @_resolve_symbol_ext @resolve_symbol_ext = ;
}

fun destroy_resolve_symbol_ext 0 {
  ext_symbols map_destroy ;
  @_resolve_symbol_ext 0 = ;
}
