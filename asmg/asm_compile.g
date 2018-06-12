
fun asmctx_parse_operand 1 {
  $ctx
  @ctx 0 param = ;
  $op
  @op SIZEOF_OPERAND malloc = ;

  $tok
  @tok ctx asmctx_get_token = ;

  # Find the size prefix
  op OPERAND_SIZE take_addr 0 = ;
  if tok "byte" strcmp 0 == {
    op OPERAND_SIZE take_addr 1 = ;
  } else {
    if tok "word" strcmp 0 == {
      op OPERAND_SIZE take_addr 2 = ;
    } else {
      if tok "dword" strcmp 0 == {
        op OPERAND_SIZE take_addr 3 = ;
      }
    }
  }
  if op OPERAND_SIZE take 0 != {
    @tok ctx asmctx_get_token = ;
  }

  # Is it direct or indirect?
  if tok **c '[' == {
    op OPERAND_TYPE take_addr 0 = ;
    
  } else {
    op OPERAND_SIZE take 0 == "Cannot specify the size of a direct operand" assert_msg ;
    $reg
    @reg tok parse_register = ;
    if reg 0xffffffff != {
      op OPERAND_TYPE take_addr 1 = ;
      op OPERAND_REG take_addr reg 0x0f & = ;
      op OPERAND_SIZE take_addr reg 4 >> = ;
    } else {
      op OPERAND_TYPE take_addr 2 = ;
      $syms
      @syms ctx ASMCTX_SYMBOLS take = ;
      if syms tok map_has {
        op OPERAND_OFFSET take_addr syms tok map_at = ;
      } else {
        $endptr
        op OPERAND_OFFSET take_addr tok @endptr 0 strtol = ;
        endptr **c 0 == "asmctx_parse_operand: illegal direct operand" assert_msg ;
      }
    }
  }

  op ret ;
}

fun asmctx_parse_line 1 {
  $ctx
  @ctx 0 param = ;
  $tok
  @tok ctx asmctx_get_token = ;
  while tok "\n" strcmp 0 == {
    tok free ;
    @tok ctx asmctx_get_token = ;
  }
  if tok "" strcmp 0 == {
    tok free ;
    0 ret ;
  }
  $opcode_map
  @opcode_map get_opcode_map = ;
  if opcode_map tok map_has {
    $opcode
    @opcode opcode_map tok map_at = ;
    $i
    @i 0 = ;
    $ops
    @ops 4 vector_init = ;
    $op
    while i opcode OPCODE_ARG_NUM take 1 - < {
      tok free ;
      @op ctx asmctx_parse_operand = ;
      ops op vector_push_back ;
      @tok ctx asmctx_get_token = ;
      tok "," strcmp 0 == "parse_asm_line: expected comma" assert_msg ;
      tok free ;
      @i i 1 + = ;
    }
    @op ctx asmctx_parse_operand = ;
    ops op vector_push_back ;
    opcode ops opcode OPCODE_HANDLER take \2 ;
    ops free_vect_of_ptrs ;
  } else {
    $label
    @label tok = ;
    @tok ctx asmctx_get_token = ;
    tok ":" strcmp 0 == "parse_asm_line: wrong syntax after label" assert_msg ;
    tok free ;
    ctx label ctx ASMCTX_CURRENT_LOC take asmctx_add_symbol ;
    label free ;
  }
  @tok ctx asmctx_get_token = ;
  tok "\n" strcmp 0 == "parse_asm_line: expected line terminator" assert_msg ;
  tok free ;
  1 ret ;
}

fun asmctx_compile 1 {
  $ctx
  @ctx 0 param = ;

  ctx ASMCTX_STAGE take_addr 0 = ;
  $start_loc
  @start_loc 0 = ;
  $size
  while ctx ASMCTX_STAGE take 3 < {
    ctx ASMCTX_FDIN take platform_reset_file ;
    ctx ASMCTX_CURRENT_LOC take_addr start_loc = ;
    $cont
    @cont 1 = ;
    while cont {
      @cont ctx asmctx_parse_line = ;
    }
    if ctx ASMCTX_STAGE take 0 == {
      @size ctx ASMCTX_CURRENT_LOC take start_loc - = ;
      @start_loc size malloc = ;
    } else {
      ctx ASMCTX_CURRENT_LOC take start_loc - size == "asmctx_compile: error 1" assert_msg ;
    }
    ctx ASMCTX_STAGE take_addr ctx ASMCTX_STAGE take 1 + = ;
  }
  "Assembled program has size " 1 platform_log ;
  size itoa 1 platform_log ;
  " and starts at " 1 platform_log ;
  start_loc itoa 1 platform_log ;
  "\n" 1 platform_log ;
}

fun parse_asm 1 {
  $filename
  @filename 0 param = ;
  $ctx
  @ctx asmctx_init = ;
  $cont
  @cont 1 = ;
  ctx filename platform_open_file asmctx_set_fd ;
  ctx asmctx_compile ;
  #while cont {
    #$tok
    #@tok ctx asmctx_get_token = ;
    #@cont tok **c 0 != = ;
    #if tok **c '\n' == {
    #  "NL" 1 platform_log ;
    #} else {
    #  tok 1 platform_log ;
    #}
    #"#" 1 platform_log ;
    #tok free ;
    @cont ctx asmctx_parse_line = ;
  #}
  #"\n" 1 platform_log ;
  ctx asmctx_destroy ;
}
