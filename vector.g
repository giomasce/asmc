
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
  vptr VECTOR_CAP take_addr INITIAL_CAP 0 = ;
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

fun vector_at 2 {
  $vptr
  $idx
  @vptr 1 param = ;
  @idx 0 param = ;
  vptr VECTOR_DATA take idx vptr VECTOR_SIZEOF_ELEM take * + ** ret ;
}

fun vector_push_back 2 {
  $vptr
  $elem
  @vptr 1 param = ;
  @elem 0 param = ;
  if vptr VECTOR_SIZE take vptr VECTOR_CAP take == {
    vptr VECTOR_CAP take_addr vptr VECTOR_CAP take 2 * = ;
    vptr VECTOR_DATA take_addr vptr VECTOR_CAP take vptr VECTOR_SIZEOF_ELEM take * vptr VECTOR_DATA take realloc = ;
  }
  vptr VECTOR_DATA take vptr VECTOR_SIZE take vptr VECTOR_SIZEOF_ELEM take * + elem = ;
  vptr VECTOR_SIZE take_addr vptr VECTOR_SIZE take 1 + = ;
  vptr VECTOR_SIZE take ret ;
}

fun vector_size 1 {
  $vptr
  @vptr 0 param = ;
  vptr VECTOR_SIZE take ret ;
}