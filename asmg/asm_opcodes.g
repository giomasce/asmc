
$_opcode_map

const OPCODE_ARG_NUM 0
const OPCODE_HANDLER 4
const SIZEOF_OPCODE 8

fun add_like_handler 1 {
  "Add like handler\n" 1 platform_log ;
}

fun mul_like_handler 1 {
  "Mul like handler\n" 1 platform_log ;
}

fun build_opcode_map 0 {
  $opcode_map
  @opcode_map map_init = ;
  $opcode
  $name

  @name "add" = ;
  @opcode SIZEOF_OPCODE malloc = ;
  opcode OPCODE_ARG_NUM take_addr 2 = ;
  opcode OPCODE_HANDLER take_addr @add_like_handler = ;
  opcode_map name opcode map_set ;

  @name "mul" = ;
  @opcode SIZEOF_OPCODE malloc = ;
  opcode OPCODE_ARG_NUM take_addr 1 = ;
  opcode OPCODE_HANDLER take_addr @mul_like_handler = ;
  opcode_map name opcode map_set ;

  @_opcode_map opcode_map = ;
}

fun get_opcode_map 0 {
  if _opcode_map ! {
    build_opcode_map ;
  }
  _opcode_map ret ;
}