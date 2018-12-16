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

const MAP_ELEM_KEY 0
const MAP_ELEM_VALUE 4
const MAP_ELEM_PRESENT 8
const SIZEOF_MAP_ELEM 12

fun map_init 0 {
  SIZEOF_MAP_ELEM vector_init ret ;
}

fun map_destroy 1 {
  $ptr
  @ptr 0 param = ;
  $i
  @i 0 = ;
  while i ptr vector_size < {
    ptr i vector_at_addr MAP_ELEM_KEY take free ;
    @i i 1 + = ;
  }
  ptr vector_destroy ;
}

fun _map_find_idx 2 {
  $map
  $key
  @map 1 param = ;
  @key 0 param = ;
  $i
  @i 0 = ;
  while i map vector_size < {
    if key map i vector_at_addr MAP_ELEM_KEY take strcmp 0 == {
      i ret ;
    }
    @i i 1 + = ;
  }
  0xffffffff ret ;
}

fun map_at 2 {
  $map
  $key
  @map 1 param = ;
  @key 0 param = ;
  $idx
  @idx map key _map_find_idx = ;
  idx 0xffffffff != "map_at: key does not exist" assert_msg ;
  $addr
  @addr map idx vector_at_addr = ;
  addr MAP_ELEM_PRESENT take "map_at: element is not present" assert_msg ;
  addr MAP_ELEM_VALUE take ret ;
}

fun map_has 2 {
  $map
  $key
  @map 1 param = ;
  @key 0 param = ;
  $idx
  @idx map key _map_find_idx = ;
  if idx 0xffffffff == {
    0 ret ;
  }
  $addr
  @addr map idx vector_at_addr = ;
  addr MAP_ELEM_PRESENT take ret ;
}

fun map_set 3 {
  $map
  $key
  $value
  @map 2 param = ;
  @key 1 param = ;
  @value 0 param = ;
  $idx
  @idx map key _map_find_idx = ;
  $addr
  if idx 0xffffffff != {
    @addr map idx vector_at_addr = ;
  } else {
    @idx map 0 vector_push_back = ;
    @addr map idx vector_at_addr = ;
    addr MAP_ELEM_KEY take_addr key strdup = ;
  }
  addr MAP_ELEM_PRESENT take_addr 1 = ;
  addr MAP_ELEM_VALUE take_addr value = ;
}

fun map_erase 2 {
  $map
  $key
  @map 1 param = ;
  @key 0 param = ;
  $idx
  @idx map key _map_find_idx = ;
  if idx 0xffffffff != {
    $addr
    @addr map idx vector_at_addr = ;
    addr MAP_ELEM_PRESENT take_addr 0 = ;
  }
}

fun map_size 1 {
  $map
  @map 0 param = ;
  map vector_size ret ;
}

fun map_foreach 3 {
  $map
  $func
  $ctx
  @map 2 param = ;
  @func 1 param = ;
  @ctx 0 param = ;

  $i
  @i 0 = ;
  while i map vector_size < {
    $addr
    @addr map i vector_at_addr = ;
    if addr MAP_ELEM_PRESENT take {
      ctx addr MAP_ELEM_KEY take addr MAP_ELEM_VALUE take func \3 ;
    }
    @i i 1 + = ;
  }
}
