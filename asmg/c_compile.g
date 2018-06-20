
const TYPE_KIND_BASE 0
const TYPE_KIND_POINTER 1
const TYPE_KIND_FUNCTION 2
const TYPE_KIND_ARRAY 3
const TYPE_KIND_STRUCT 4
const TYPE_KIND_UNION 5
const TYPE_KIND_ENUM 6

const TYPE_KIND 0
const TYPE_BASE 4
const TYPE_SIZE 8
const SIZEOF_TYPE 12

fun type_init 0 {
  $type
  @type SIZEOF_TYPE malloc = ;
  type ret ;
}

fun type_destroy 1 {
  $type
  @type 0 param = ;
  type free ;
}

# Name is a vector of char*
const TYPENAME_NAME 0
const TYPENAME_TYPE 4
const SIZEOF_TYPENAME 8

fun typename_init 0 {
  $typename
  @typename SIZEOF_TYPENAME malloc = ;
  typename TYPENAME_NAME take_addr 4 vector_init = ;
  typename ret ;
}

fun typename_destroy 1 {
  $typename
  @typename 0 param = ;
  typename TYPENAME_NAME take free_vect_of_ptrs ;
  typename free ;
}

const GLOBAL_TYPE 0
const SIZEOF_GLOBAL 4

fun global_init 0 {
  $global
  @global SIZEOF_GLOBAL malloc = ;
  global ret ;
}

fun global_destroy 1 {
  $global
  @global 0 param = ;
  global free ;
}

const CCTX_TYPES 0
const CCTX_TYPENAMES 4
const CCTX_GLOBALS 8
const SIZEOF_CCTX 12

fun cctx_init 0 {
  $ctx
  @ctx SIZEOF_CCTX malloc = ;
  ctx CCTX_TYPES take_addr 4 vector_init = ;
  ctx CCTX_TYPENAMES take_addr 4 vector_init = ;
  ctx CCTX_GLOBALS take_addr map_init = ;
  ctx ret ;
}

fun cctx_destroy 1 {
  $ctx
  @ctx 0 param = ;

  $types
  @types ctx CCTX_TYPES take = ;
  $i
  @i 0 = ;
  while i types vector_size < {
    types i vector_at type_destroy ;
    @i i 1 + = ;
  }
  types vector_destroy ;

  $typenames
  @typenames ctx CCTX_TYPENAMES take = ;
  @i 0 = ;
  while i typenames vector_size < {
    typenames i vector_at typename_destroy ;
    @i i 1 + = ;
  }
  typenames vector_destroy ;

  $globals
  @globals ctx CCTX_GLOBALS take = ;
  @i 0 = ;
  while i globals map_size < {
    if globals i map_has_idx {
      globals i map_at_idx global_destroy ;
    }
    @i i 1 + = ;
  }
  globals map_destroy ;

  ctx free ;
}

fun c_compile 2 {

}

fun test 0 {
  $v
  @v 4 malloc = ;
  v 2 + 0x4c =c ;
  v free ;
}

fun parse_c 1 {
  $ctx
  @ctx ppctx_init = ;
  $cctx
  @cctx cctx_init = ;
  $tokens
  @tokens 4 vector_init = ;
  tokens ctx 0 param preproc_file ;
  @tokens tokens remove_whites = ;
  "Finished preprocessing\n" 1 platform_log ;
  $i
  @i 0 = ;
  while i tokens vector_size < {
    $tok
    @tok tokens i vector_at = ;
    if tok **c '\n' == {
      "NL" 1 platform_log ;
    } else {
      tok 1 platform_log ;
    }
    "#" 1 platform_log ;
    @i i 1 + = ;
  }
  "\n" 1 platform_log ;
  tokens free_vect_of_ptrs ;
  cctx cctx_destroy ;
  ctx ppctx_destroy ;
}
