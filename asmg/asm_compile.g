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
    $stolen
    @stolen str len + 1 - **c = ;
    str len + 1 - 0 =c ;
    @value str @endptr 2 strtol = ;
    if endptr **c 0 == {
      value ret ;
    }
    str len + 1 - stolen =c ;
  }

  if str len + 1 - **c 'h' == str len + 1 - **c 'H' == || {
    $stolen
    @stolen str len + 1 - **c = ;
    str len + 1 - 0 =c ;
    @value str @endptr 16 strtol = ;
    if endptr **c 0 == {
      value ret ;
    }
    str len + 1 - stolen =c ;
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
          tok free ;
          @tok ctx asmctx_get_token = ;
          if tok "shl" strcmp 0 == {
            tok free ;
            @tok ctx asmctx_get_token = ;
            $shift
            @shift ctx tok asmctx_parse_number = ;
            @opvalue opvalue shift << = ;
            tok free ;
            @tok ctx asmctx_get_token = ;
          } else {
            if tok "shr" strcmp 0 == {
              tok free ;
              @tok ctx asmctx_get_token = ;
              $shift
              @shift ctx tok asmctx_parse_number = ;
              @opvalue opvalue shift << = ;
              tok free ;
              @tok ctx asmctx_get_token = ;
            } else {
              if tok "or" strcmp 0 == {
                tok free ;
                @tok ctx asmctx_get_token = ;
                $op2
                @op2 ctx tok asmctx_parse_number = ;
                @opvalue opvalue op2 | = ;
                tok free ;
                @tok ctx asmctx_get_token = ;
              } else {
                if tok "*" strcmp 0 == {
                  tok free ;
                  @tok ctx asmctx_get_token = ;
                  $op2
                  @op2 ctx tok asmctx_parse_number = ;
                  @opvalue opvalue op2 * = ;
                  tok free ;
                  @tok ctx asmctx_get_token = ;
                }
              }
            }
          }
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
      tok free ;
    } else {
      if tok "?" strcmp 0 == {
        tok free ;
        ctx 0 asmctx_emit ;
      } else {
        ctx asmctx_give_back_token ;
        $op
        @op ctx asmctx_parse_operand = ;
        op OPERAND_TYPE take 2 == "asmctx_parse_db: immediate operand expected" assert_msg ;
        $value
        @value op OPERAND_OFFSET take = ;
        op free ;
        ctx value asmctx_emit ;
      }
    }
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

  $type
  $size
  $arg
  @type 0 = ;
  @size 0 = ;
  @arg 0 = ;

  $tok
  @tok ctx asmctx_get_token = ;
  if tok "align" strcmp 0 == {
    @type 3 = ;
    @size 1 = ;
  } else {
    if tok strlen 2 != type 0 == && {
      ctx asmctx_give_back_token ;
      0 ret ;
    }

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
  }
  if type 0 == size 0 == || {
    ctx asmctx_give_back_token ;
    0 ret ;
  }
  tok free ;

  if type 1 == {
    @tok ctx asmctx_get_token = ;
    $value
    if tok "?" strcmp 0 == {
      tok free ;
      ctx 0 size emit_size ;
    } else {
      ctx asmctx_give_back_token ;
      $cont
      @cont 1 = ;
      while cont {
        $op
        @op ctx asmctx_parse_operand = ;
        op OPERAND_TYPE take 2 == "asmctx_parse_data: immediate operand expected" assert_msg ;
        $value
        @value op OPERAND_OFFSET take = ;
        op free ;
        ctx value size emit_size ;
        @tok ctx asmctx_get_token = ;
        if tok "," strcmp 0 == {
          tok free ;
        } else {
          @cont 0 = ;
          ctx asmctx_give_back_token ;
        }
      }
    }
  } else {
    $op
    @op ctx asmctx_parse_operand = ;
    op OPERAND_TYPE take 2 == "asmctx_parse_data: immediate operand expected" assert_msg ;
    $reps
    if type 2 == {
      @reps op OPERAND_OFFSET take = ;
    } else {
      $align
      @align op OPERAND_OFFSET take = ;
      $rem
      @rem ctx ASMCTX_CURRENT_LOC take align % = ;
      if rem 0 == {
        @reps 0 = ;
      } else {
        @reps align rem - = ;
      }
    }
    op free ;
    while reps 0 > {
      ctx 0 size emit_size ;
      @reps reps 1 - = ;
    }
  }

  1 ret ;
}

fun asmctx_parse_operands 1 {
  $ctx
  @ctx 0 param = ;

  $ops
  @ops 4 vector_init = ;
  $cont
  @cont 1 = ;
  while cont {
    $tok
    @tok ctx asmctx_get_token = ;
    if tok "\n" strcmp 0 == {
      @cont 0 = ;
      ctx asmctx_give_back_token ;
    } else {
      ctx asmctx_give_back_token ;
      $op
      @op ctx asmctx_parse_operand = ;
      ops op vector_push_back ;
      @tok ctx asmctx_get_token = ;
      if tok "," strcmp 0 != {
        @cont 0 = ;
        ctx asmctx_give_back_token ;
      } else {
        tok free ;
      }
    }
  }

  ops ret ;
}

fun asmctx_parse_line 2 {
  $ctx
  $opcode_map
  @ctx 1 param = ;
  @opcode_map 0 param = ;

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
      @ops ctx asmctx_parse_operands = ;
      arg_num 0xff == arg_num ops vector_size == || "asmctx_parse_line: wrong number of operands" assert_msg ;
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

fun asmctx_compile 1 {
  $ctx
  @ctx 0 param = ;

  ctx ASMCTX_STAGE take_addr 0 = ;
  $start_loc
  @start_loc 0 = ;
  $size
  $opcode_map
  @opcode_map build_opcode_map = ;
  while ctx ASMCTX_STAGE take 3 < {
    if ctx ASMCTX_VERBOSE take {
      "Compilation stage " 1 platform_log ;
      ctx ASMCTX_STAGE take 1 + itoa 1 platform_log ;
    }
    $line_num
    @line_num 1 = ;
    ctx ASMCTX_FDIN take vfs_reset ;
    ctx ASMCTX_CURRENT_LOC take_addr start_loc = ;
    ctx ASMCTX_TOKEN_GIVEN_BACK take_addr 0 = ;
    ctx ASMCTX_CHAR_GIVEN_BACK take_addr 0 = ;
    $cont
    @cont 1 = ;
    while cont {
      if line_num 1000 % 0 == ctx ASMCTX_VERBOSE take && {
        "." 1 platform_log ;
      }
      line_num set_assert_pos ;
      @cont ctx opcode_map asmctx_parse_line = ;
      @line_num line_num 1 + = ;
    }
    if ctx ASMCTX_VERBOSE take {
      "\n" 1 platform_log ;
    }
    if ctx ASMCTX_STAGE take 0 == {
      @size ctx ASMCTX_CURRENT_LOC take start_loc - = ;
      @start_loc size platform_allocate = ;
    } else {
      ctx ASMCTX_CURRENT_LOC take start_loc - size == "asmctx_compile: error 1" assert_msg ;
    }
    ctx ASMCTX_STAGE take_addr ctx ASMCTX_STAGE take 1 + = ;
  }
  if ctx ASMCTX_VERBOSE take {
    "Assembled program has size " 1 platform_log ;
    size itoa 1 platform_log ;
    " and starts at " 1 platform_log ;
    start_loc itoa 1 platform_log ;
    "\n" 1 platform_log ;
  }
  if ctx ASMCTX_DEBUG take {
    "Compiled dump:\n" 1 platform_log ;
    start_loc size dump_mem ;
    "\n" 1 platform_log ;
  }
  opcode_map destroy_opcode_map ;
}

fun parse_asm 1 {
  $filename
  @filename 0 param = ;
  $ctx
  @ctx asmctx_init = ;
  $cont
  @cont 1 = ;
  $fd
  @fd filename vfs_open = ;
  ctx fd asmctx_set_fd ;
  # while cont {
  #   $tok
  #   @tok ctx asmctx_get_token = ;
  #   @cont tok **c 0 != = ;
  #   if tok **c '\n' == {
  #     "NL" 1 platform_log ;
  #   } else {
  #     tok 1 platform_log ;
  #   }
  #   "#" 1 platform_log ;
  #   tok free ;
  # }
  # "\n" 1 platform_log ;
  ctx asmctx_compile ;
  fd vfs_close ;
  ctx asmctx_destroy ;
}
