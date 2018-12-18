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

const AVL_LEFT 0
const AVL_RIGHT 4
const AVL_KEY 8
const AVL_VALUE 12
const AVL_PARENT 16
const SIZEOF_AVL 20

fun avl_init 2 {
  $key
  $parent
  @key 1 param = ;
  @parent 0 param = ;

  $avl
  @avl SIZEOF_AVL malloc = ;
  avl AVL_LEFT take_addr 0 = ;
  avl AVL_RIGHT take_addr 0 = ;
  avl AVL_KEY take_addr key strdup = ;
  avl AVL_VALUE take_addr 0 = ;
  avl AVL_PARENT take_addr parent = ;
  avl ret ;
}

fun avl_destroy 1 {
  $avl
  @avl 0 param = ;

  if avl AVL_LEFT take 0 != {
    avl AVL_LEFT take avl_destroy ;
  }
  if avl AVL_RIGHT take 0 != {
    avl AVL_RIGHT take avl_destroy ;
  }
  avl AVL_KEY take free ;
  avl free ;
}

const MAP_AVL 0
const MAP_SIZE 4
const SIZEOF_MAP 8

fun map_init 0 {
  $map
  @map SIZEOF_MAP malloc = ;
  map MAP_AVL take_addr 0 = ;
  map MAP_SIZE take_addr 0 = ;
  map ret ;
}

fun map_destroy 1 {
  $map
  @map 0 param = ;

  if map MAP_AVL take 0 != {
    map MAP_AVL take avl_destroy ;
  }
  map free ;
}

fun _map_find 3 {
  $map
  $key
  $create
  @map 2 param = ;
  @key 1 param = ;
  @create 0 param = ;

  $avl
  @avl map MAP_AVL take = ;
  $ptr
  @ptr map MAP_AVL take_addr = ;
  $parent
  @parent 0 = ;
  while 1 {
    if avl 0 == {
      if create {
        @avl key parent avl_init = ;
        ptr avl = ;
        map MAP_SIZE take_addr map MAP_SIZE take 1 + = ;
        avl ret ;
      } else {
        0 ret ;
      }
    }
    $cmp
    @cmp key avl AVL_KEY take strcmp = ;
    if cmp 0 == {
      avl ret ;
    }
    if cmp 0 < {
      @ptr avl AVL_LEFT take_addr = ;
      @parent avl = ;
      @avl avl AVL_LEFT take = ;
    } else {
      @ptr avl AVL_RIGHT take_addr = ;
      @parent avl = ;
      @avl avl AVL_RIGHT take = ;
    }
  }
}

fun map_at 2 {
  $map
  $key
  @map 1 param = ;
  @key 0 param = ;

  $avl
  @avl map key 0 _map_find = ;
  avl 0 != "map_at: key does not exist" assert_msg ;

  # "map_at(" 1 platform_log ;
  # key 1 platform_log ;
  # ") = " 1 platform_log ;
  # avl AVL_VALUE take itoa 1 platform_log ;
  # "\n" 1 platform_log ;

  avl AVL_VALUE take ret ;
}

fun map_has 2 {
  $map
  $key
  @map 1 param = ;
  @key 0 param = ;

  $avl
  @avl map key 0 _map_find = ;

  # "map_has(" 1 platform_log ;
  # key 1 platform_log ;
  # ") = " 1 platform_log ;
  # avl 0 != itoa 1 platform_log ;
  # "\n" 1 platform_log ;

  avl 0 != ret ;
}

fun map_set 3 {
  $map
  $key
  $value
  @map 2 param = ;
  @key 1 param = ;
  @value 0 param = ;

  $avl
  @avl map key 1 _map_find = ;
  avl 0 != "map_set: error 1" assert_msg ;

  # "map_set(" 1 platform_log ;
  # key 1 platform_log ;
  # ", " 1 platform_log ;
  # value itoa 1 platform_log ;
  # ")\n" 1 platform_log ;

  avl AVL_VALUE take_addr value = ;
}

fun _map_erase_leaf 2 {
  $map
  $avl
  @map 1 param = ;
  @avl 0 param = ;

  map MAP_SIZE take_addr map MAP_SIZE take 1 - = ;
  avl AVL_LEFT take 0 == "_map_erase_leaf: has left child" assert_msg ;
  avl AVL_RIGHT take 0 == "_map_erase_leaf: has right child" assert_msg ;

  $parent
  @parent avl AVL_PARENT take = ;
  avl avl_destroy ;
  if parent 0 == {
    map MAP_AVL take avl == "_map_erase_leaf: wrong root" assert_msg ;
    map MAP_AVL take_addr 0 = ;
    ret ;
  }

  if parent AVL_LEFT take avl == {
    parent AVL_LEFT take_addr 0 = ;
    ret ;
  }
  if parent AVL_RIGHT take avl == {
    parent AVL_RIGHT take_addr 0 = ;
    ret ;
  }
  0 "_map_erase_leaf: cannot find among parent's children" assert_msg ;
}

fun _avl_swap 2 {
  $avl
  $avl2
  @avl 1 param = ;
  @avl2 0 param = ;

  $tmp
  @tmp avl AVL_VALUE take = ;
  avl AVL_VALUE take_addr avl2 AVL_VALUE take = ;
  avl2 AVL_VALUE take_addr tmp = ;
  @tmp avl AVL_KEY take = ;
  avl AVL_KEY take_addr avl2 AVL_KEY take = ;
  avl2 AVL_KEY take_addr tmp = ;
}

fun _map_erase 2 {
  $map
  $avl
  @map 1 param = ;
  @avl 0 param = ;

  if avl 0 != {
    if avl AVL_LEFT take 0 != {
      $avl2
      @avl2 avl AVL_LEFT take = ;
      while avl2 AVL_RIGHT take 0 != {
        @avl2 avl2 AVL_RIGHT take = ;
      }
      avl avl2 _avl_swap ;
      map avl2 _map_erase ;
      ret ;
    }
    if avl AVL_RIGHT take 0 != {
      $avl2
      @avl2 avl AVL_RIGHT take = ;
      while avl2 AVL_LEFT take 0 != {
        @avl2 avl2 AVL_LEFT take = ;
      }
      avl avl2 _avl_swap ;
      map avl2 _map_erase ;
      ret ;
    }
    map avl _map_erase_leaf ;
  }
}

fun map_erase 2 {
  $map
  $key
  @map 1 param = ;
  @key 0 param = ;

  $avl
  @avl map key 0 _map_find = ;
  map avl _map_erase ;

  # "map_erase(" 1 platform_log ;
  # key 1 platform_log ;
  # ")\n" 1 platform_log ;
}

fun map_size 1 {
  $map
  @map 0 param = ;

  map MAP_SIZE take ret ;
}

fun _map_foreach 3 {
  $avl
  $func
  $ctx
  @avl 2 param = ;
  @func 1 param = ;
  @ctx 0 param = ;

  if avl 0 == {
    ret ;
  }
  avl AVL_LEFT take func ctx _map_foreach ;
  ctx avl AVL_KEY take avl AVL_VALUE take func \3 ;
  avl AVL_RIGHT take func ctx _map_foreach ;
}

fun map_foreach 3 {
  $map
  $func
  $ctx
  @map 2 param = ;
  @func 1 param = ;
  @ctx 0 param = ;

  map MAP_AVL take func ctx _map_foreach ;
}
