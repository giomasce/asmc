
const MAP_ELEM_KEY 0
const MAP_ELEM_VALUE 4
const MAP_ELEM_PRESENT 8
const SIZEOF_MAP_ELEM 12

fun map_init 0 {
  SIZEOF_MAP_ELEM vector_init ret ;
}

fun map_destroy 1 {
  0 param vector_destroy ;
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
  idx 0xffffffff != assert ;
  $addr
  @addr map idx vector_at_addr = ;
  addr MAP_ELEM_PRESENT take assert ;
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
