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

const VECTOR_DATA 0
const VECTOR_SIZE 4
const VECTOR_CAP 8
const VECTOR_SIZEOF_ELEM 12
const SIZEOF_VECTOR 16

const INITIAL_CAP 1

fun vector_init 1 {
  $vptr
  @vptr SIZEOF_VECTOR malloc = ;
  vptr VECTOR_SIZE take_addr 0 = ;
  vptr VECTOR_CAP take_addr INITIAL_CAP = ;
  vptr VECTOR_SIZEOF_ELEM take_addr 0 param = ;
  vptr VECTOR_DATA take_addr vptr VECTOR_CAP take vptr VECTOR_SIZEOF_ELEM take * malloc = ;
  vptr ret ;
}

fun vector_destroy 1 {
  $vptr
  @vptr 0 param = ;
  vptr VECTOR_DATA take free ;
  vptr free ;
}

fun vector_clear 1 {
  $vptr
  @vptr 0 param = ;
  vptr VECTOR_SIZE take_addr 0 = ;
}

fun vector_data 1 {
  $vptr
  @vptr 0 param = ;
  vptr VECTOR_DATA take ret ;
}

fun vector_at_addr 2 {
  $vptr
  $idx
  @vptr 1 param = ;
  @idx 0 param = ;
  idx 0 >= "vector_at_addr: negative vector access" idx vptr VECTOR_SIZE take assert_msg_int_int ;
  idx vptr VECTOR_SIZE take < "vector_at_addr: vector access out of bounds" idx vptr VECTOR_SIZE take assert_msg_int_int ;
  vptr VECTOR_DATA take idx vptr VECTOR_SIZEOF_ELEM take * + ret ;
}

fun vector_at 2 {
  $vptr
  $idx
  @vptr 1 param = ;
  @idx 0 param = ;
  idx 0 >= "vector_at: negative vector access" idx vptr VECTOR_SIZE take assert_msg_int_int ;
  idx vptr VECTOR_SIZE take < "vector_at: vector access out of bounds" idx vptr VECTOR_SIZE take assert_msg_int_int ;
  vptr VECTOR_DATA take idx vptr VECTOR_SIZEOF_ELEM take * + ** ret ;
}

fun vector_push_back 2 {
  $vptr
  $elem
  @vptr 1 param = ;
  @elem 0 param = ;
  vptr VECTOR_SIZE take vptr VECTOR_CAP take <= "Internal error: size > capacity" assert_msg ;
  if vptr VECTOR_SIZE take vptr VECTOR_CAP take == {
    vptr VECTOR_CAP take_addr vptr VECTOR_CAP take 2 * = ;
    vptr VECTOR_DATA take_addr vptr VECTOR_CAP take vptr VECTOR_SIZEOF_ELEM take * vptr VECTOR_DATA take realloc = ;
  }
  vptr VECTOR_SIZE take vptr VECTOR_CAP take < "Internal error: size >= capacity again" assert_msg ;
  vptr VECTOR_DATA take vptr VECTOR_SIZE take vptr VECTOR_SIZEOF_ELEM take * + elem = ;
  vptr VECTOR_SIZE take_addr vptr VECTOR_SIZE take 1 + = ;
  vptr VECTOR_SIZE take 1 - ret ;
}

fun vector_pop_back 1 {
  $vptr
  @vptr 0 param = ;
  vptr VECTOR_SIZE take 0 > "Popping from empty vector" assert_msg ;
  vptr VECTOR_SIZE take_addr vptr VECTOR_SIZE take 1 - = ;
  vptr VECTOR_DATA take vptr VECTOR_SIZE take vptr VECTOR_SIZEOF_ELEM take * + ** ret ;
}

fun vector_size 1 {
  $vptr
  @vptr 0 param = ;
  vptr VECTOR_SIZE take ret ;
}

fun vector_has 2 {
  $vptr
  $elem
  @vptr 1 param = ;
  @elem 0 param = ;

  $i
  @i 0 = ;
  while i vptr vector_size < {
    if vptr i vector_at elem == {
      1 ret ;
    }
    @i i 1 + = ;
  }
  0 ret ;
}

fun vector_test 0 {
  $v
  @v 4 vector_init = ;
  v 22 vector_push_back ;
  v 23 vector_push_back ;
  v 24 vector_push_back ;
  v 25 vector_push_back ;
  v 26 vector_push_back ;
  v 22 vector_push_back ;
  v 23 vector_push_back ;
  v 24 vector_push_back ;
  v 25 vector_push_back ;
  v 26 vector_push_back ;
  v 22 vector_push_back ;
  v 23 vector_push_back ;
  v 24 vector_push_back ;
  v 25 vector_push_back ;
  v 26 vector_push_back ;
  v 100 vector_push_back ;
  v 22 vector_push_back ;
  v 23 vector_push_back ;
  v 24 vector_push_back ;
  v 25 vector_push_back ;
  v 26 vector_push_back ;
  v 22 vector_push_back ;
  v 23 vector_push_back ;
  v 24 vector_push_back ;
  v 25 vector_push_back ;
  v 26 vector_push_back ;
  v 22 vector_push_back ;
  v 23 vector_push_back ;
  v 24 vector_push_back ;
  v 25 vector_push_back ;
  v 26 vector_push_back ;
  v 100 vector_push_back ;
  $i
  @i 0 = ;
  while i v vector_size < {
    $elem
    @elem v i vector_at = ;
    elem itoa 1 platform_log ;
    "\n" 1 platform_log ;
    @i i 1 + = ;
  }
}
