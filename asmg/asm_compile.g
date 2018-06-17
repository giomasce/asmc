
fun asmctx_parse_number 2 {
  $ctx
  $str
  @ctx 1 param = ;
  @str 0 param = ;

  $len
  @len str strlen = ;
  len 0 > "asmctx_parse_number: invalid zero-length string" assert_msg ;

  $value

  if str **c '\'' == {
    @value 0 = ;
    str len + 1 - **c '\'' == "asmctx_parse_number: invalid immediate character" assert_msg ;
    str len + 1 - 0 =c ;
    @str str 1 + = ;
    $i
    @i 0 = ;
    while str i + **c 0 != {
      @value value 8 << = ;
      @value value str i + **c + = ;
      @i i 1 + = ;
    }
    value ret ;
  }

  $endptr
  @value str @endptr 0 strtol = ;
  if endptr **c 0 == {
    value ret ;
  }

  if str len + 1 - **c 'b' == str len + 1 - **c 'B' == || {
    str len + 1 - 0 =c ;
    @value str @endptr 2 strtol = ;
    if endptr **c 0 == {
      value ret ;
    }
  }

  if str len + 1 - **c 'h' == str len + 1 - **c 'H' == || {
    str len + 1 - 0 =c ;
    @value str @endptr 16 strtol = ;
    if endptr **c 0 == {
      value ret ;
    }
  }

  @value ctx str asmctx_get_symbol = ;
  value ret ;
}

fun asmctx_parse_operand 1 {
  $ctx
  @ctx 0 param = ;
  $op
  @op SIZEOF_OPERAND malloc = ;

  $tok
  @tok ctx asmctx_get_token = ;

  # Find the size prefix
  op OPERAND_SIZE take_addr 0 = ;
  if tok "byte" strcmp_case 0 == {
    op OPERAND_SIZE take_addr 1 = ;
  } else {
    if tok "word" strcmp_case 0 == {
      op OPERAND_SIZE take_addr 2 = ;
    } else {
      if tok "dword" strcmp_case 0 == {
        op OPERAND_SIZE take_addr 3 = ;
      }
    }
  }
  if op OPERAND_SIZE take 0 != {
    tok free ;
    @tok ctx asmctx_get_token = ;
  }

  # Is it direct or indirect?
  if tok "[" strcmp 0 == {
    op OPERAND_TYPE take_addr 0 = ;
    op OPERAND_OFFSET take_addr 0 = ;
    op OPERAND_REG take_addr 8 = ;
    op OPERAND_INDEX_REG take_addr 8 = ;
    op OPERAND_SEGMENT take_addr 0 = ;
    $cont
    @cont 1 = ;
    tok free ;
    @tok ctx asmctx_get_token = ;
    $sign
    @sign 1 = ;
    while cont {
      $reg
      @reg tok parse_register = ;
      if reg 0xffffffff != {
        sign 1 == "asmctx_parse_operand: illegal sign usage in indirect operand" assert_msg ;
        reg 4 >> 3 == "asmctx_parse_operand: indirect operands must use 32 bits registers" assert_msg ;
        @reg reg 0xf & = ;
        tok free ;
        @tok ctx asmctx_get_token = ;
        if tok "*" strcmp 0 == {
          tok free ;
          @tok ctx asmctx_get_token = ;
          $scale
          $endptr
          @scale tok @endptr 0 strtol = ;
          endptr **c 0 == "asmctx_parse_operand: illegal scale" assert_msg ;
          $scalebits
          if scale 1 == {
            @scalebits 0 = ;
          } else {
            if scale 2 == {
              @scalebits 1 = ;
            } else {
              if scale 4 == {
                @scalebits 2 = ;
              } else {
                if scale 8 == {
                  @scalebits 3 = ;
                } else {
                  0 "asmctx_parse_operand: illegal scale" assert_msg ;
                }
              }
            }
          }
          op OPERAND_INDEX_REG take_addr reg = ;
          op OPERAND_SCALE take_addr scalebits = ;
          tok free ;
        } else {
          ctx asmctx_give_back_token ;
          if op OPERAND_REG take 8 == {
            op OPERAND_REG take_addr reg = ;
          } else {
            op OPERAND_INDEX_REG take 8 == "asmctx_parse_operand: more than two registers in indirect operand" assert_msg ;
            op OPERAND_INDEX_REG take_addr reg = ;
            op OPERAND_SCALE take_addr 0 = ;
          }
        }
      } else {
        $value
        @value ctx tok asmctx_parse_number = ;
        op OPERAND_OFFSET take_addr op OPERAND_OFFSET take value sign * + = ;
        tok free ;
      }
      @tok ctx asmctx_get_token = ;
      if tok "]" strcmp 0 == {
        tok free ;
        @cont 0 = ;
      } else {
        if tok "+" strcmp 0 == {
          tok free ;
          @tok ctx asmctx_get_token = ;
          @sign 1 = ;
        } else {
          if tok "-" strcmp 0 == {
            tok free ;
            @tok ctx asmctx_get_token = ;
            @sign 0 1 -  = ;
          } else {
            0 "asmctx_parse_operand: illegal character while scanning an indirect operand" assert_msg ;
          }
        }
      }
    }
  } else {
    op OPERAND_SIZE take 0 == "Cannot specify the size of a direct operand" assert_msg ;
    $cont
    @cont 1 = ;
    $value
    @value 0 = ;
    op OPERAND_TYPE take_addr 0 = ;
    $sign
    @sign 0 = ;
    while cont {
      $reg
      @reg tok parse_register = ;
      if reg 0xffffffff != {
        op OPERAND_TYPE take 0 == "asmctx_parse_operand: invalid direct operand" assert_msg ;
        op OPERAND_TYPE take_addr 1 = ;
        op OPERAND_REG take_addr reg 0x0f & = ;
        op OPERAND_SIZE take_addr reg 4 >> = ;
        @cont 0 = ;
        tok free ;
      } else {
        if tok "+" strcmp 0 == tok "-" strcmp 0 == || tok "not" strcmp 0 == || ! {
          op OPERAND_TYPE take 0 == op OPERAND_TYPE take 2 == || "asmctx_parse_operand: invalid direct operand" assert_msg ;
          op OPERAND_TYPE take_addr 2 = ;
          $opvalue
          @opvalue ctx tok asmctx_parse_number = ;
          if sign 0 == {
            @value value opvalue + = ;
          } else {
            if sign 1 == {
              @value value opvalue - = ;
            } else {
              if sign 2 == {
                @value value opvalue - 1 - = ;
              } else {
                0 "asmctx_parse_operand: error 1" assert_msg ;
              }
            }
          }
          tok free ;
          @tok ctx asmctx_get_token = ;
        }
        if tok "+" strcmp 0 == {
          tok free ;
          @tok ctx asmctx_get_token = ;
          @sign 0 = ;
        } else {
          if tok "-" strcmp 0 == {
            tok free ;
            @tok ctx asmctx_get_token = ;
            @sign 1 = ;
          } else {
            if tok "not" strcmp 0 == {
              tok free ;
              @tok ctx asmctx_get_token = ;
              @sign 2 = ;
            } else {
              ctx asmctx_give_back_token ;
              @cont 0 = ;
            }
          }
        }
      }
    }
    if op OPERAND_TYPE take 2 == {
      op OPERAND_OFFSET take_addr value = ;
    }
  }

  op ret ;
}

fun asmctx_parse_db 1 {
  $ctx
  @ctx 0 param = ;

  while 1 {
    $tok
    @tok ctx asmctx_get_token = ;
    if tok **c '\'' == {
      ctx tok emit_string ;
    } else {
      ctx ctx tok asmctx_parse_number asmctx_emit ;
    }
    tok free ;
    @tok ctx asmctx_get_token = ;
    if tok "\n" strcmp 0 == {
      ctx asmctx_give_back_token ;
      ret ;
    }
    tok "," strcmp 0 == "asmctx_parse_db: comma expected" assert_msg ;
    tok free ;
  }
}

fun asmctx_parse_data 1 {
  $ctx
  @ctx 0 param = ;

  $tok
  @tok ctx asmctx_get_token = ;
  if tok strlen 2 != {
    ctx asmctx_give_back_token ;
    0 ret ;
  }

  $type
  $size
  $arg
  @type 0 = ;
  @size 0 = ;
  @arg 0 = ;

  if tok "db" strcmp 0 == {
    tok free ;
    ctx asmctx_parse_db ;
    1 ret ;
  }

  if tok **c 'd' == {
    @type 1 = ;
  }
  if tok **c 'r' == {
    @type 2 = ;
  }
  if tok 1 + **c 'b' == {
    @size 1 = ;
  }
  if tok 1 + **c 'w' == {
    @size 2 = ;
  }
  if tok 1 + **c 'd' == {
    @size 3 = ;
  }
  if tok 1 + **c 'q' == {
    @size 4 = ;
  }
  if type 0 == size 0 == || {
    ctx asmctx_give_back_token ;
    0 ret ;
  }

  tok free ;
  @tok ctx asmctx_get_token = ;
  $value
  if tok "?" strcmp 0 == {
    type 1 == "asmctx_parse_data: reservation size must be specified" assert_msg ;
    @value 0 = ;
  } else {
    @value ctx tok asmctx_parse_number = ;
  }
  tok free ;
  $reps
  @reps 1 = ;
  if type 2 == {
    @reps value = ;
    @value 0 = ;
  }

  while reps 0 > {
    if size 1 == {
      ctx value asmctx_emit ;
    }
    if size 2 == {
      ctx value asmctx_emit16 ;
    }
    if size 3 == {
      ctx value asmctx_emit32 ;
    }
    if size 4 == {
      ctx value asmctx_emit32 ;
      ctx 0 asmctx_emit32 ;
    }
    @reps reps 1 - = ;
  }

  1 ret ;
}

fun asmctx_parse_line 1 {
  $ctx
  @ctx 0 param = ;

  $tok
  @tok ctx asmctx_get_token = ;
  if tok "\n" strcmp 0 == {
    tok free ;
    1 ret ;
  }
  if tok "" strcmp 0 == {
    tok free ;
    0 ret ;
  }

  if tok "rep" strcmp 0 == tok "repe" strcmp 0 == || {
    tok free ;
    @tok ctx asmctx_get_token = ;
    ctx 0xf3 asmctx_emit ;
  }

  $opcode_map
  @opcode_map get_opcode_map = ;
  if opcode_map tok map_has {
    $opcode
    @opcode opcode_map tok map_at = ;
    tok free ;
    $i
    @i 0 = ;
    $arg_num
    @arg_num opcode OPCODE_ARG_NUM take 0xff & = ;
    $can_repeat
    @can_repeat opcode OPCODE_ARG_NUM take 8 >> = ;
    $cont
    @cont 1 = ;
    while cont {
      $ops
      @ops 4 vector_init = ;
      if arg_num 0 != {
        $op
        while i arg_num 1 - < {
          @op ctx asmctx_parse_operand = ;
          ops op vector_push_back ;
          @tok ctx asmctx_get_token = ;
          tok "," strcmp 0 == "parse_asm_line: expected comma" assert_msg ;
          tok free ;
          @i i 1 + = ;
        }
        @op ctx asmctx_parse_operand = ;
        ops op vector_push_back ;
      }
      ctx opcode ops opcode OPCODE_HANDLER take \3 ;
      ops free_vect_of_ptrs ;
      if can_repeat ! {
        @cont 0 = ;
      } else {
        @tok ctx asmctx_get_token = ;
        if tok "\n" strcmp 0 == {
          @cont 0 = ;
        }
        ctx asmctx_give_back_token ;
      }
    }
  } else {
    ctx asmctx_give_back_token ;
    if ctx asmctx_parse_data ! {
      $label
      @label ctx asmctx_get_token = ;
      @tok ctx asmctx_get_token = ;
      if tok ":" strcmp 0 == {
        tok free ;
        ctx label ctx ASMCTX_CURRENT_LOC take asmctx_add_symbol ;
      } else {
        ctx label ctx ASMCTX_CURRENT_LOC take asmctx_add_symbol ;
        ctx asmctx_give_back_token ;
        if ctx asmctx_parse_data ! {
          0 "asmctx_parse_line: unknown command" assert_msg ;
        }
      }
      label free ;
    }
  }
  @tok ctx asmctx_get_token = ;
  tok "\n" strcmp 0 == "parse_asm_line: expected line terminator" assert_msg ;
  tok free ;
  1 ret ;
}

fun dump_nibble 1 {
  $x
  @x 0 param = ;
  @x x 0xf & = ;
  if x 0 == { '0' 1 platform_write_char ; }
  if x 1 == { '1' 1 platform_write_char ; }
  if x 2 == { '2' 1 platform_write_char ; }
  if x 3 == { '3' 1 platform_write_char ; }
  if x 4 == { '4' 1 platform_write_char ; }
  if x 5 == { '5' 1 platform_write_char ; }
  if x 6 == { '6' 1 platform_write_char ; }
  if x 7 == { '7' 1 platform_write_char ; }
  if x 8 == { '8' 1 platform_write_char ; }
  if x 9 == { '9' 1 platform_write_char ; }
  if x 10 == { 'a' 1 platform_write_char ; }
  if x 11 == { 'b' 1 platform_write_char ; }
  if x 12 == { 'c' 1 platform_write_char ; }
  if x 13 == { 'd' 1 platform_write_char ; }
  if x 14 == { 'e' 1 platform_write_char ; }
  if x 15 == { 'f' 1 platform_write_char ; }
}

fun dump_byte 1 {
  $x
  @x 0 param = ;
  x 4 >> dump_nibble ;
  x dump_nibble ;
  ' ' 1 platform_write_char ;
}

fun dump_mem 2 {
  $ptr
  $size
  @ptr 1 param = ;
  @size 0 param = ;

  @size size ptr + = ;
  while ptr size < {
    ptr **c dump_byte ;
    @ptr ptr 1 + = ;
  }
}

fun asmctx_compile 1 {
  $ctx
  @ctx 0 param = ;

  ctx ASMCTX_STAGE take_addr 0 = ;
  $start_loc
  @start_loc 0 = ;
  $size
  while ctx ASMCTX_STAGE take 3 < {
    $line_num
    @line_num 1 = ;
    ctx ASMCTX_FDIN take platform_reset_file ;
    ctx ASMCTX_CURRENT_LOC take_addr start_loc = ;
    $cont
    @cont 1 = ;
    while cont {
      line_num set_assert_pos ;
      @cont ctx asmctx_parse_line = ;
      @line_num line_num 1 + = ;
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
  "Compiled dump:\n" 1 platform_log ;
  start_loc size dump_mem ;
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
