# This file is part of asmc, a bootstrapping OS with minimal seed
# https://gitlab.com/giomasce/asmc

# This file is based on the red-black tree implementation available at
# [1] (now archived at [2]), which is dedicated to the public domain
# according to the CC0 1.0 Universal Public Domain Dedication [3]. The
# original authors are unknown. The code was translated from C to G by
# Giovanni Mascellani <gio@debian.org>, with some small changes
# (marked by XXX comments). The translation is also dedicated to the
# public domain according to the same terms as the original work.

# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
# EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
# MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
# IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY
# CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
# TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
# SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

#  [1] http://en.literateprograms.org/Special:DownloadCode/Red-black_tree_(C)
#  [2] https://web.archive.org/web/20140329042423/http://en.literateprograms.org/Special:DownloadCode/Red-black_tree_(C)).
#  [3] https://creativecommons.org/publicdomain/zero/1.0/

const RB_RED 0
const RB_BLACK 1

const RB_KEY 0
const RB_VALUE 4
const RB_LEFT 8
const RB_RIGHT 12
const RB_PARENT 16
const RB_COLOR 20
const SIZEOF_RB 24

const MAP_ROOT 0
const MAP_SIZE 4
const SIZEOF_MAP 8

ifun rb_rbtree_create 0
ifun rb_rbtree_lookup 3
ifun rb_rbtree_insert 4
ifun rb_rbtree_delete 3

ifun rb_grandparent 1
ifun rb_sibling 1
ifun rb_uncle 1
ifun rb_verify_properties 1
ifun rb_verify_property_1 1
ifun rb_verify_property_2 1
ifun rb_verify_property_4 1
ifun rb_verify_property_5 1
ifun rb_node_color 1
ifun rb_verify_property_5_helper 3

ifun rb_new_node 5
ifun rb_lookup_node 3
ifun rb_rotate_left 2
ifun rb_rotate_right 2

ifun rb_replace_node 3
ifun rb_insert_case1 2
ifun rb_insert_case2 2
ifun rb_insert_case3 2
ifun rb_insert_case4 2
ifun rb_insert_case5 2
ifun rb_maximum_node 1
ifun rb_delete_case1 2
ifun rb_delete_case2 2
ifun rb_delete_case3 2
ifun rb_delete_case4 2
ifun rb_delete_case5 2
ifun rb_delete_case6 2


fun rb_rbtree_create 0 {
  $t
  @t SIZEOF_MAP malloc = ;
  t MAP_ROOT take_addr 0 = ;
  t MAP_SIZE take_addr 0 = ;
  t rb_verify_properties ;
  t ret ;
}

fun rb_rbtree_lookup 3 {
  $t
  $key
  $compare
  @t 2 param = ;
  @key 1 param = ;
  @compare 0 param = ;

  $n
  @n t key compare rb_lookup_node = ;
  # XXX Fail if the node does not exist
  n 0 != "rb_rbtree_lookup: node not present" assert_msg ;
  n RB_VALUE take ret ;
}

fun rb_rbtree_insert 4 {
  $t
  $key
  $value
  $compare
  @t 3 param = ;
  @key 2 param = ;
  @value 1 param = ;
  @compare 0 param = ;

  $inserted_node
  @inserted_node key value RB_RED 0 0 rb_new_node = ;
  if t MAP_ROOT take 0 == {
    t MAP_ROOT take_addr inserted_node = ;
  } else {
    $n
    @n t MAP_ROOT take = ;
    # XXX Introduce variable cont to emulate break
    $cont
    @cont 1 = ;
    while cont {
      $comp_result
      @comp_result key n RB_KEY take compare \2 = ;
      if comp_result 0 == {
        n RB_VALUE take_addr value = ;
        # FIXME reference lost!
        ret ;
      } else {
        if comp_result 0 < {
          if n RB_LEFT take 0 == {
            n RB_LEFT take_addr inserted_node = ;
            @cont 0 = ;
          } else {
            @n n RB_LEFT take = ;
          }
        } else {
          comp_result 0 > "rb_rbtree_insert: error 1" assert_msg ;
          if n RB_RIGHT take 0 == {
            n RB_RIGHT take_addr inserted_node = ;
            @cont 0 = ;
          } else {
            @n n RB_RIGHT take = ;
          }
        }
      }
    }
    inserted_node RB_PARENT take_addr n = ;
  }
  t inserted_node rb_insert_case1 ;
  t rb_verify_properties ;
}

fun rb_rbtree_delete 3 {
  $t
  $key
  $compare
  @t 2 param = ;
  @key 1 param = ;
  @compare 0 param = ;

  $child
  $n
  @n t key compare rb_lookup_node = ;
  if n 0 == {
    # XXX Return zero to indicate that no deletion took place
    0 ret ;
  }
  if n RB_LEFT take 0 != n RB_RIGHT take 0 != && {
    $pred
    @pred n RB_LEFT take rb_maximum_node = ;
    # XXX Swap values instead of copying pred over n, so that proper
    # cleanup can be done later
    $tmp
    @tmp n RB_KEY take = ;
    n RB_KEY take_addr pred RB_KEY take = ;
    pred RB_KEY take_addr tmp = ;
    @tmp n RB_VALUE take = ;
    n RB_VALUE take_addr pred RB_VALUE take = ;
    pred RB_VALUE take_addr tmp = ;
    @n pred = ;
  }

  n RB_LEFT take 0 == n RB_RIGHT take 0 == || "rb_rbtree_delete: error 1" assert_msg ;
  if n RB_RIGHT take 0 == {
    @child n RB_LEFT take = ;
  } else {
    @child n RB_RIGHT take = ;
  }

  if n rb_node_color RB_BLACK == {
    n RB_COLOR take_addr child rb_node_color = ;
    t n rb_delete_case1 ;
  }
  t n child rb_replace_node ;
  if n RB_PARENT take 0 == child 0 != && {
    child RB_COLOR take_addr RB_BLACK = ;
  }

  # FIXME
  n free ;

  t rb_verify_properties ;
}

fun rb_grandparent 1 {
  $n
  @n 0 param = ;

  n 0 != "rb_grandparent: node is null" assert_msg ;
  n RB_PARENT take 0 != "rb_grandparent: parent is null" assert_msg ;
  n RB_PARENT take RB_PARENT take 0 != "rb_grandparent: grandparent is null" assert_msg ;
  n RB_PARENT take RB_PARENT take ret ;
}

fun rb_sibling 1 {
  $n
  @n 0 param = ;

  n 0 != "rb_sibling: node is null" assert_msg ;
  n RB_PARENT take 0 != "rb_sibling: parent is null" assert_msg ;
  if n n RB_PARENT take RB_LEFT take == {
    n RB_PARENT take RB_RIGHT take ret ;
  } else {
    n RB_PARENT take RB_LEFT take ret ;
  }
}

fun rb_uncle 1 {
  $n
  @n 0 param = ;

  n 0 != "rb_uncle: node is null" assert_msg ;
  n RB_PARENT take 0 != "rb_uncle: parent is null" assert_msg ;
  n RB_PARENT take RB_PARENT take 0 != "rb_uncle: grandparent is null" assert_msg ;
  n RB_PARENT take rb_sibling ret ;
}

fun rb_verify_properties 1 {
  $t
  @t 0 param = ;

  # Uncomment to disable verification
  #ret ;

  t MAP_ROOT take rb_verify_property_1 ;
  t MAP_ROOT take rb_verify_property_2 ;
  t MAP_ROOT take rb_verify_property_4 ;
  t MAP_ROOT take rb_verify_property_5 ;
}

fun rb_verify_property_1 1 {
  $n
  @n 0 param = ;

  n rb_node_color RB_RED == n rb_node_color RB_BLACK == || "rb_verify_property_1: failed" assert_msg ;
  if n 0 == {
    ret ;
  }
  n RB_LEFT take rb_verify_property_1 ;
  n RB_RIGHT take rb_verify_property_1 ;
}

fun rb_verify_property_2 1 {
  $root
  @root 0 param = ;

  root rb_node_color RB_BLACK == "rb_verify_property_2: failed" assert_msg ;
}

fun rb_verify_property_4 1 {
  $n
  @n 0 param = ;

  if n rb_node_color RB_RED == {
    n RB_LEFT take rb_node_color RB_BLACK == "rb_verify_property_4: failed on left" assert_msg ;
    n RB_RIGHT take rb_node_color RB_BLACK == "rb_verify_property_4: failed on right" assert_msg ;
    n RB_PARENT take rb_node_color RB_BLACK == "rb_verify_property_4: failed on parent" assert_msg ;
  }
  if n 0 == {
    ret ;
  }
  n RB_LEFT take rb_verify_property_4 ;
  n RB_RIGHT take rb_verify_property_4 ;
}

fun rb_verify_property_5 1 {
  $root
  @root 0 param = ;

  $black_count_path
  @black_count_path 0 1 - = ;
  root 0 @black_count_path rb_verify_property_5_helper ;
}

fun rb_verify_property_5_helper 3 {
  $n
  $black_count
  $path_black_count
  @n 2 param = ;
  @black_count 1 param = ;
  @path_black_count 0 param = ;

  if n rb_node_color RB_BLACK == {
    @black_count black_count 1 + = ;
  }
  if n 0 == {
    if path_black_count ** 0 1 - == {
      path_black_count black_count = ;
    } else {
      path_black_count ** black_count == "rb_verify_property_5_helper: failed" assert_msg ;
    }
    ret ;
  }
  n RB_LEFT take black_count path_black_count rb_verify_property_5_helper ;
  n RB_RIGHT take black_count path_black_count rb_verify_property_5_helper ;
}

fun rb_node_color 1 {
  $n
  @n 0 param = ;

  if n 0 == {
    RB_BLACK ret ;
  } else {
    n RB_COLOR take ret ;
  }
}

fun rb_new_node 5 {
  $key
  $value
  $node_color
  $left
  $right
  @key 4 param = ;
  @value 3 param = ;
  @node_color 2 param = ;
  @left 1 param = ;
  @right 0 param = ;

  $result
  @result SIZEOF_RB malloc = ;
  result RB_KEY take_addr key = ;
  result RB_VALUE take_addr value = ;
  result RB_COLOR take_addr node_color = ;
  result RB_LEFT take_addr left = ;
  result RB_RIGHT take_addr right = ;
  if left 0 != {
    left RB_PARENT take_addr result = ;
  }
  if right 0 != {
    right RB_PARENT take_addr result = ;
  }
  result RB_PARENT take_addr 0 = ;
  result ret ;
}

fun rb_lookup_node 3 {
  $t
  $key
  $compare
  @t 2 param = ;
  @key 1 param = ;
  @compare 0 param = ;

  $n
  @n t MAP_ROOT take = ;
  while n 0 != {
    $comp_result
    @comp_result key n RB_KEY take compare \2 = ;
    if comp_result 0 == {
      n ret ;
    } else {
      if comp_result 0 < {
        @n n RB_LEFT take = ;
      } else {
        comp_result 0 > "rb_lookup_node: error 1" assert_msg ;
        @n n RB_RIGHT take = ;
      }
    }
  }
  n ret ;
}

fun rb_rotate_left 2 {
  $t
  $n
  @t 1 param = ;
  @n 0 param = ;

  $r
  @r n RB_RIGHT take = ;
  t n r rb_replace_node ;
  n RB_RIGHT take_addr r RB_LEFT take = ;
  if r RB_LEFT take 0 != {
    r RB_LEFT take RB_PARENT take_addr n = ;
  }
  r RB_LEFT take_addr n = ;
  n RB_PARENT take_addr r = ;
}

fun rb_rotate_right 2 {
  $t
  $n
  @t 1 param = ;
  @n 0 param = ;

  $L
  @L n RB_LEFT take = ;
  t n L rb_replace_node ;
  n RB_LEFT take_addr L RB_RIGHT take = ;
  if L RB_RIGHT take 0 != {
    L RB_RIGHT take RB_PARENT take_addr n = ;
  }
  L RB_RIGHT take_addr n = ;
  n RB_PARENT take_addr L = ;
}

fun rb_replace_node 3 {
  $t
  $oldn
  $newn
  @t 2 param = ;
  @oldn 1 param = ;
  @newn 0 param = ;

  if oldn RB_PARENT take 0 == {
    t MAP_ROOT take_addr newn = ;
  } else {
    if oldn oldn RB_PARENT take RB_LEFT take == {
      oldn RB_PARENT take RB_LEFT take_addr newn = ;
    } else {
      oldn RB_PARENT take RB_RIGHT take_addr newn = ;
    }
  }
  if newn 0 != {
    newn RB_PARENT take_addr oldn RB_PARENT take = ;
  }
}

fun rb_insert_case1 2 {
  $t
  $n
  @t 1 param = ;
  @n 0 param = ;

  if n RB_PARENT take 0 == {
    n RB_COLOR take_addr RB_BLACK = ;
  } else {
    t n rb_insert_case2 ;
  }
}

fun rb_insert_case2 2 {
  $t
  $n
  @t 1 param = ;
  @n 0 param = ;

  if n RB_PARENT take rb_node_color RB_BLACK == {
    ret ;
  } else {
    t n rb_insert_case3 ;
  }
}

fun rb_insert_case3 2 {
  $t
  $n
  @t 1 param = ;
  @n 0 param = ;

  if n rb_uncle rb_node_color RB_RED == {
    n RB_PARENT take RB_COLOR take_addr RB_BLACK = ;
    n rb_uncle RB_COLOR take_addr RB_BLACK = ;
    n rb_grandparent RB_COLOR take_addr RB_RED = ;
    t n rb_grandparent rb_insert_case1 ;
  } else {
    t n rb_insert_case4 ;
  }
}

fun rb_insert_case4 2 {
  $t
  $n
  @t 1 param = ;
  @n 0 param = ;

  if n n RB_PARENT take RB_RIGHT take == n RB_PARENT take n rb_grandparent RB_LEFT take == && {
    t n RB_PARENT take rb_rotate_left ;
    @n n RB_LEFT take = ;
  } else {
    if n n RB_PARENT take RB_LEFT take == n RB_PARENT take n rb_grandparent RB_LEFT take == && {
      t n RB_PARENT take rb_rotate_right ;
      @n n RB_RIGHT take = ;
    }
  }
  t n rb_insert_case5 ;
}

fun rb_insert_case5 2 {
  $t
  $n
  @t 1 param = ;
  @n 0 param = ;

  n RB_PARENT take RB_COLOR take_addr RB_BLACK = ;
  n rb_grandparent RB_COLOR take_addr RB_RED = ;
  if n n RB_PARENT take RB_LEFT take == n RB_PARENT take n rb_grandparent RB_LEFT take == && {
    t n rb_grandparent rb_rotate_right ;
  } else {
    n n RB_PARENT take RB_RIGHT take == n RB_PARENT take n rb_grandparent RB_RIGHT take == && "rb_insert_case5: error 1" assert_msg ;
    t n rb_grandparent rb_rotate_left ;
  }
}

fun rb_maximum_node 1 {
  $n
  @n 0 param = ;

  n 0 != "rb_maximum_node: null node" assert_msg ;
  while n RB_RIGHT take 0 != {
    @n n RB_RIGHT take = ;
  }
  n ret ;
}

fun rb_delete_case1 2 {
  $t
  $n
  @t 1 param = ;
  @n 0 param = ;

  if n RB_PARENT take 0 == {
    ret ;
  } else {
    t n rb_delete_case2 ;
  }
}

fun rb_delete_case2 2 {
  $t
  $n
  @t 1 param = ;
  @n 0 param = ;

  if n rb_sibling rb_node_color RB_RED == {
    n RB_PARENT take RB_COLOR take_addr RB_RED = ;
    n rb_sibling RB_COLOR take_addr RB_BLACK = ;
    if n n RB_PARENT take RB_LEFT take == {
      t n RB_PARENT take rb_rotate_left ;
    } else {
      t n RB_PARENT take rb_rotate_right ;
    }
  }
  t n rb_delete_case3 ;
}

fun rb_delete_case3 2 {
  $t
  $n
  @t 1 param = ;
  @n 0 param = ;

  if n RB_PARENT take rb_node_color RB_BLACK ==
     n rb_sibling rb_node_color RB_BLACK == &&
     n rb_sibling RB_LEFT take rb_node_color RB_BLACK == &&
     n rb_sibling RB_RIGHT take rb_node_color RB_BLACK == && {
    n rb_sibling RB_COLOR take_addr RB_RED = ;
    t n RB_PARENT take rb_delete_case1 ;
  } else {
    t n rb_delete_case4 ;
  }
}

fun rb_delete_case4 2 {
  $t
  $n
  @t 1 param = ;
  @n 0 param = ;

  if n RB_PARENT take rb_node_color RB_RED ==
     n rb_sibling rb_node_color RB_BLACK == &&
     n rb_sibling RB_LEFT take rb_node_color RB_BLACK == &&
     n rb_sibling RB_RIGHT take rb_node_color RB_BLACK == && {
    n rb_sibling RB_COLOR take_addr RB_RED = ;
    n RB_PARENT take RB_COLOR take_addr RB_BLACK = ;
  } else {
    t n rb_delete_case5 ;
  }
}

fun rb_delete_case5 2 {
  $t
  $n
  @t 1 param = ;
  @n 0 param = ;

  if n n RB_PARENT take RB_LEFT take ==
     n rb_sibling rb_node_color RB_BLACK == &&
     n rb_sibling RB_LEFT take rb_node_color RB_RED == &&
     n rb_sibling RB_RIGHT take rb_node_color RB_BLACK == && {
    n rb_sibling RB_COLOR take_addr RB_RED = ;
    n rb_sibling RB_LEFT take RB_COLOR take_addr RB_BLACK = ;
    t n rb_sibling rb_rotate_right ;
  } else {
    if n n RB_PARENT take RB_RIGHT take ==
       n rb_sibling rb_node_color RB_BLACK == &&
       n rb_sibling RB_RIGHT take rb_node_color RB_RED == &&
       n rb_sibling RB_LEFT take rb_node_color RB_BLACK == && {
      n rb_sibling RB_COLOR take_addr RB_RED = ;
      n rb_sibling RB_RIGHT take RB_COLOR take_addr RB_BLACK = ;
      t n rb_sibling rb_rotate_left ;
    }
  }
  t n rb_delete_case6 ;
}

fun rb_delete_case6 2 {
  $t
  $n
  @t 1 param = ;
  @n 0 param = ;

  n rb_sibling RB_COLOR take_addr n RB_PARENT take rb_node_color = ;
  n RB_PARENT take RB_COLOR take_addr RB_BLACK = ;
  if n n RB_PARENT take RB_LEFT take == {
    n rb_sibling RB_RIGHT take rb_node_color RB_RED == "rb_delete_case6: error 1" assert_msg ;
    n rb_sibling RB_RIGHT take RB_COLOR take_addr RB_BLACK = ;
    t n RB_PARENT take rb_rotate_left ;
  } else {
    n rb_sibling RB_LEFT take rb_node_color RB_RED == "rb_delete_case6: error2" assert_msg ;
    n rb_sibling RB_LEFT take RB_COLOR take_addr RB_BLACK = ;
    t n RB_PARENT take rb_rotate_right ;
  }
}
