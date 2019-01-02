# This file is part of asmc, a bootstrapping OS with minimal seed
# Copyright (C) 2018-2019 Giovanni Mascellani <gio@debian.org>
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

const ASTINT_GET_TOKEN 0
const ASTINT_GET_TOKEN_OR_FAIL 4
const ASTINT_GIVE_BACK_TOKEN 8
const ASTINT_PARSE_TYPE 12

const AST_TYPE 0             # 0 for operand, 1 for operator
const AST_NAME 4             # char*
const AST_LEFT 8             # AST*
const AST_CENTER 12          # AST*
const AST_RIGHT 16           # AST*
const AST_TYPE_IDX 20        # int
const AST_ORIG_TYPE_IDX 24   # int
const AST_CAST_TYPE_IDX 28   # int
const AST_VALUE 32           # int64*
const SIZEOF_AST 36

fun ast_init 0 {
  $ptr
  @ptr SIZEOF_AST malloc = ;
  ptr AST_TYPE take_addr 0 = ;
  ptr AST_NAME take_addr 0 = ;
  ptr AST_LEFT take_addr 0 = ;
  ptr AST_CENTER take_addr 0 = ;
  ptr AST_RIGHT take_addr 0 = ;
  ptr AST_TYPE_IDX take_addr 0xffffffff = ;
  ptr AST_ORIG_TYPE_IDX take_addr 0xffffffff = ;
  ptr AST_CAST_TYPE_IDX take_addr 0xffffffff = ;
  ptr AST_VALUE take_addr 0 = ;
  ptr ret ;
}

fun ast_destroy 1 {
  $ptr
  @ptr 0 param = ;
  ptr AST_NAME take free ;
  if ptr AST_LEFT take {
    ptr AST_LEFT take ast_destroy ;
  }
  if ptr AST_CENTER take {
    ptr AST_CENTER take ast_destroy ;
  }
  if ptr AST_RIGHT take {
    ptr AST_RIGHT take ast_destroy ;
  }
  if ptr AST_VALUE take {
    ptr AST_VALUE take i64_destroy ;
  }
  ptr free ;
}

fun ast_is_operator 1 {
  $str
  @str 0 param = ;
  str "++" strcmp 0 ==
    str "--" strcmp 0 == ||
    str "." strcmp 0 == ||
    str "->" strcmp 0 == ||
    str "defined" strcmp 0 == ||
    str "+" strcmp 0 == ||
    str "-" strcmp 0 == ||
    str "!" strcmp 0 == ||
    str "~" strcmp 0 == ||
    str "*" strcmp 0 == ||
    str "&" strcmp 0 == ||
    str "sizeof" strcmp 0 == ||
    str "/" strcmp 0 == ||
    str "%" strcmp 0 == ||
    str "<<" strcmp 0 == ||
    str ">>" strcmp 0 == ||
    str "<" strcmp 0 == ||
    str "<=" strcmp 0 == ||
    str ">" strcmp 0 == ||
    str ">=" strcmp 0 == ||
    str "==" strcmp 0 == ||
    str "!=" strcmp 0 == ||
    str "^" strcmp 0 == ||
    str "|" strcmp 0 == ||
    str "&&" strcmp 0 == ||
    str "||" strcmp 0 == ||
    str "?" strcmp 0 == ||
    str "=" strcmp 0 == ||
    str "+=" strcmp 0 == ||
    str "-=" strcmp 0 == ||
    str "*=" strcmp 0 == ||
    str "/=" strcmp 0 == ||
    str "%=" strcmp 0 == ||
    str "<<=" strcmp 0 == ||
    str ">>=" strcmp 0 == ||
    str "&=" strcmp 0 == ||
    str "^=" strcmp 0 == ||
    str "|=" strcmp 0 == ||
    str "," strcmp 0 == ||
    ret ;
}

# See http://en.cppreference.com/w/c/language/operator_precedence
fun ast_get_priority 1 {
  $str
  @str 0 param = ;
  if str "++_POST" strcmp 0 == { 1 ret ; }
  if str "--_POST" strcmp 0 == { 1 ret ; }
  if str "(" strcmp 0 == { 1 ret ; }
  if str "[" strcmp 0 == { 1 ret ; }
  if str "." strcmp 0 == { 1 ret ; }
  if str "->" strcmp 0 == { 1 ret ; }
  if str "defined_PRE" strcmp 0 == { 2 ret ; }
  if str "++_PRE" strcmp 0 == { 2 ret ; }
  if str "--_PRE" strcmp 0 == { 2 ret ; }
  if str "+_PRE" strcmp 0 == { 2 ret ; }
  if str "-_PRE" strcmp 0 == { 2 ret ; }
  if str "!_PRE" strcmp 0 == { 2 ret ; }
  if str "~_PRE" strcmp 0 == { 2 ret ; }
  if str "(_PRE" strcmp 0 == { 2 ret ; }
  if str "*_PRE" strcmp 0 == { 2 ret ; }
  if str "&_PRE" strcmp 0 == { 2 ret ; }
  if str "sizeof" strcmp 0 == { 2 ret ; }
  if str "*" strcmp 0 == { 3 ret ; }
  if str "/" strcmp 0 == { 3 ret ; }
  if str "%" strcmp 0 == { 3 ret ; }
  if str "+" strcmp 0 == { 4 ret ; }
  if str "-" strcmp 0 == { 4 ret ; }
  if str "<<" strcmp 0 == { 5 ret ; }
  if str ">>" strcmp 0 == { 5 ret ; }
  if str "<" strcmp 0 == { 6 ret ; }
  if str "<=" strcmp 0 == { 6 ret ; }
  if str ">" strcmp 0 == { 6 ret ; }
  if str ">=" strcmp 0 == { 6 ret ; }
  if str "==" strcmp 0 == { 7 ret ; }
  if str "!=" strcmp 0 == { 7 ret ; }
  if str "&" strcmp 0 == { 8 ret ; }
  if str "^" strcmp 0 == { 9 ret ; }
  if str "|" strcmp 0 == { 10 ret ; }
  if str "&&" strcmp 0 == { 11 ret ; }
  if str "||" strcmp 0 == { 12 ret ; }
  if str "?" strcmp 0 == { 13 ret ; }
  if str "=" strcmp 0 == { 14 ret ; }
  if str "+=" strcmp 0 == { 14 ret ; }
  if str "-=" strcmp 0 == { 14 ret ; }
  if str "*=" strcmp 0 == { 14 ret ; }
  if str "/=" strcmp 0 == { 14 ret ; }
  if str "%=" strcmp 0 == { 14 ret ; }
  if str "<<=" strcmp 0 == { 14 ret ; }
  if str ">>=" strcmp 0 == { 14 ret ; }
  if str "&=" strcmp 0 == { 14 ret ; }
  if str "^=" strcmp 0 == { 14 ret ; }
  if str "|=" strcmp 0 == { 14 ret ; }
  if str "," strcmp 0 == { 15 ret ; }
  if str " " strcmp 0 == { 100 ret ; }
  0 "Not an operator" str assert_msg_str ;
}

# See http://en.cppreference.com/w/c/language/operator_precedence
# 0 is right-to-left
# 1 is left-to-right
fun ast_get_ass_direction 1 {
  $str
  @str 0 param = ;
  if str "++_POST" strcmp 0 == { 1 ret ; }
  if str "--_POST" strcmp 0 == { 1 ret ; }
  if str "(" strcmp 0 == { 1 ret ; }
  if str "[" strcmp 0 == { 1 ret ; }
  if str "." strcmp 0 == { 1 ret ; }
  if str "->" strcmp 0 == { 1 ret ; }
  if str "defined_PRE" strcmp 0 == { 0 ret ; }
  if str "++_PRE" strcmp 0 == { 0 ret ; }
  if str "--_PRE" strcmp 0 == { 0 ret ; }
  if str "+_PRE" strcmp 0 == { 0 ret ; }
  if str "-_PRE" strcmp 0 == { 0 ret ; }
  if str "!_PRE" strcmp 0 == { 0 ret ; }
  if str "~_PRE" strcmp 0 == { 0 ret ; }
  if str "(_PRE" strcmp 0 == { 0 ret ; }
  if str "*_PRE" strcmp 0 == { 0 ret ; }
  if str "&_PRE" strcmp 0 == { 0 ret ; }
  if str "sizeof" strcmp 0 == { 0 ret ; }
  if str "*" strcmp 0 == { 1 ret ; }
  if str "/" strcmp 0 == { 1 ret ; }
  if str "%" strcmp 0 == { 1 ret ; }
  if str "+" strcmp 0 == { 1 ret ; }
  if str "-" strcmp 0 == { 1 ret ; }
  if str "<<" strcmp 0 == { 1 ret ; }
  if str ">>" strcmp 0 == { 1 ret ; }
  if str "<" strcmp 0 == { 1 ret ; }
  if str "<=" strcmp 0 == { 1 ret ; }
  if str ">" strcmp 0 == { 1 ret ; }
  if str ">=" strcmp 0 == { 1 ret ; }
  if str "==" strcmp 0 == { 1 ret ; }
  if str "!=" strcmp 0 == { 1 ret ; }
  if str "&" strcmp 0 == { 1 ret ; }
  if str "^" strcmp 0 == { 1 ret ; }
  if str "|" strcmp 0 == { 1 ret ; }
  if str "&&" strcmp 0 == { 1 ret ; }
  if str "||" strcmp 0 == { 1 ret ; }
  if str "?" strcmp 0 == { 0 ret ; }
  if str "=" strcmp 0 == { 0 ret ; }
  if str "+=" strcmp 0 == { 0 ret ; }
  if str "-=" strcmp 0 == { 0 ret ; }
  if str "*=" strcmp 0 == { 0 ret ; }
  if str "/=" strcmp 0 == { 0 ret ; }
  if str "%=" strcmp 0 == { 0 ret ; }
  if str "<<=" strcmp 0 == { 0 ret ; }
  if str ">>=" strcmp 0 == { 0 ret ; }
  if str "&=" strcmp 0 == { 0 ret ; }
  if str "^=" strcmp 0 == { 0 ret ; }
  if str "|=" strcmp 0 == { 0 ret ; }
  if str "," strcmp 0 == { 1 ret ; }
  if str " " strcmp 0 == { 0 ret ; }
  0 "Not an operator" str assert_msg_str ;
}

fun ast_rewind_stack 3 {
  $operator_stack
  $operand_stack
  $center_stack
  @operator_stack 2 param = ;
  @operand_stack 1 param = ;
  @center_stack 0 param = ;

  operand_stack vector_size operator_stack vector_size == "Stacks do not have the same size" assert_msg ;
  operand_stack vector_size center_stack vector_size == "Stacks do not have the same size" assert_msg ;

  $cont
  @cont 1 = ;
  while operator_stack vector_size 2 >= cont && {
    $last_pri
    $nlast_pri
    $dir
    @last_pri operator_stack operator_stack vector_size 1 - vector_at ast_get_priority = ;
    @nlast_pri operator_stack operator_stack vector_size 2 - vector_at ast_get_priority = ;
    @dir operator_stack operator_stack vector_size 1 - vector_at ast_get_ass_direction = ;
    if last_pri nlast_pri > last_pri nlast_pri == dir && || {
      $ast
      @ast ast_init = ;
      $tmp
      $tmp2
      $center
      @tmp operator_stack vector_pop_back = ;
      @tmp2 center_stack vector_pop_back = ;
      ast AST_TYPE take_addr 1 = ;
      ast AST_RIGHT take_addr operand_stack vector_pop_back = ;
      ast AST_LEFT take_addr operand_stack vector_pop_back = ;
      ast AST_NAME take_addr operator_stack vector_pop_back = ;
      @center center_stack vector_pop_back = ;
      operand_stack ast vector_push_back ;
      operator_stack tmp vector_push_back ;
      center_stack tmp2 vector_push_back ;
      # Sanity check
      if ast AST_NAME take "?" strcmp 0 == {
        center 0 != "ast_rewind_stack: ternary operator misses center operand" assert_msg ;
        ast AST_CENTER take_addr center = ;
      } else {
        if ast AST_NAME take "(_PRE" strcmp 0 == {
          center 0xffffffff 0 != "ast_rewind_stack: cast operator misses type index" assert_msg ;
          ast AST_CAST_TYPE_IDX take_addr center = ;
        } else {
          ast AST_CENTER take 0 == "ast_rewind_stack: center operand for non-ternary operator" assert_msg ;
        }
      }
    } else {
      @cont 0 = ;
    }
    operand_stack vector_size operator_stack vector_size == "Stacks do not have the same size" assert_msg ;
    operand_stack vector_size center_stack vector_size == "Stacks do not have the same size" assert_msg ;
  }
}

ifun ast_parse1 2

fun ast_parsev 2 {
  $int
  $end_toks
  @int 1 param = ;
  @end_toks 0 param = ;

  $cont
  @cont 1 = ;
  $expect_operator
  @expect_operator 0 = ;
  $operator_stack
  @operator_stack 4 vector_init = ;
  $operand_stack
  @operand_stack 4 vector_init = ;
  $center_stack
  @center_stack 4 vector_init = ;
  # "Beginning parse\n" 1 platform_log ;
  while cont {
    $tok
    $stop
    @stop 0 = ;
    @tok int int ASTINT_GET_TOKEN take \1 = ;
    if tok 0 == {
      @stop 1 = ;
    }
    $i
    @i 0 = ;
    while i end_toks vector_size < stop ! && {
      if end_toks i vector_at tok strcmp 0 == {
        int int ASTINT_GIVE_BACK_TOKEN take \1 ;
        @stop 1 = ;
      }
      @i i 1 + = ;
    }
    if stop {
      @cont 0 = ;
    } else {
      if " " tok strcmp 0 != {
        $is_operator
        @is_operator tok ast_is_operator = ;
        # "Found: " 1 platform_log ;
        # tok 1 platform_log ;
        # if is_operator {
        #   " (operator)" 1 platform_log ;
        # } else {
        #   " (operand)" 1 platform_log ;
        # }
        # "\n" 1 platform_log ;
        if expect_operator {
          if is_operator {
            $center_ast
            @center_ast 0 = ;
            # Operator as we expect, push it in the operator stack.
            # If the operator is postfix, mangle it and push
            # a placeholder operand in the operand stack
            $is_postfix
            @is_postfix 0 = ;
            if tok "++" strcmp 0 == {
              @tok "++_POST" = ;
              @is_postfix 1 = ;
            }
            if tok "--" strcmp 0 == {
              @tok "--_POST" = ;
              @is_postfix 1 = ;
            }
            # If this is the ternary operator, parse the center part
            # immediately
            if tok "?" strcmp 0 == {
              @center_ast int ":" ast_parse1 = ;
              int int ASTINT_GET_TOKEN_OR_FAIL take \1 ":" strcmp 0 == "ast_parsev: error 1" assert_msg ;
            }
            operator_stack tok strdup vector_push_back ;
            center_stack center_ast vector_push_back ;
            operator_stack operand_stack center_stack ast_rewind_stack ;
            if is_postfix {
              operand_stack ast_init vector_push_back ;
            } else {
              @expect_operator 0 = ;
            }
          } else {
            $ast
            # Here we treat the argument-separating comma as the
            # comma operator; this is not correct, in theory, because
            # it makes a((b,c),d) the same thing as a(b,c,d). However
            # we hope that no sane program relies on that.
            if tok "(" strcmp 0 == {
              $tok2
              @tok2 int int ASTINT_GET_TOKEN_OR_FAIL take \1 = ;
              if tok2 ")" strcmp 0 == {
                # No arguments, push a placeholder
                @ast ast_init = ;
              } else {
                # Roll back token and parse arguments
                int int ASTINT_GIVE_BACK_TOKEN take \1 ;
                @ast int ")" ast_parse1 = ;
                int int ASTINT_GET_TOKEN_OR_FAIL take \1 ")" strcmp 0 == "ast_parsev: error 2" assert_msg ;
              }
              operator_stack tok strdup vector_push_back ;
              center_stack 0 vector_push_back ;
              operator_stack operand_stack center_stack ast_rewind_stack ;
              operand_stack ast vector_push_back ;
            } else {
              if tok "[" strcmp 0 == {
                @ast int "]" ast_parse1 = ;
                int int ASTINT_GET_TOKEN_OR_FAIL take \1 "]" strcmp 0 == "ast_parsev: error 3" assert_msg ;
                operator_stack tok strdup vector_push_back ;
                center_stack 0 vector_push_back ;
                operator_stack operand_stack center_stack ast_rewind_stack ;
                operand_stack ast vector_push_back ;
              } else {
                # Operand instead of operator: error!
                0 "Operand instead of operator" assert_msg ;
              }
            }
          }
        } else {
          if is_operator {
            # Operator instead of operand, it must be a prefix.
            # Mangle it, push it in the operator stack
            # and push a placeholder operand in the operand stack
            $found
            @found 0 = ;
            if tok "defined" strcmp 0 == {
              @tok "defined_PRE" = ;
              @found 1 = ;
            }
            if tok "!" strcmp 0 == {
              @tok "!_PRE" = ;
              @found 1 = ;
            }
            if tok "~" strcmp 0 == {
              @tok "~_PRE" = ;
              @found 1 = ;
            }
            if tok "++" strcmp 0 == {
              @tok "++_PRE" = ;
              @found 1 = ;
            }
            if tok "--" strcmp 0 == {
              @tok "--_PRE" = ;
              @found 1 = ;
            }
            if tok "+" strcmp 0 == {
              @tok "+_PRE" = ;
              @found 1 = ;
            }
            if tok "-" strcmp 0 == {
              @tok "-_PRE" = ;
              @found 1 = ;
            }
            if tok "*" strcmp 0 == {
              @tok "*_PRE" = ;
              @found 1 = ;
            }
            if tok "&" strcmp 0 == {
              @tok "&_PRE" = ;
              @found 1 = ;
            }
            found "Expect prefix operator" assert_msg ;
            operator_stack tok strdup vector_push_back ;
            operand_stack ast_init vector_push_back ;
            center_stack 0 vector_push_back ;
          } else {
            $ast
            if tok "(" strcmp 0 == {
              # This might be a grouping parenthesis or a cast
              # operator; I try to parse a type: if it works, it is a
              # cast (and I have to treat it as a prefix operator),
              # otherwise it is a grouping parenthesis
              $type_idx
              @type_idx int int ASTINT_PARSE_TYPE take \1 = ;
              if type_idx 0xffffffff == {
                @ast int ")" ast_parse1 = ;
                int int ASTINT_GET_TOKEN_OR_FAIL take \1 ")" strcmp 0 == "ast_parsev: error 4" assert_msg ;
                operand_stack ast vector_push_back ;
                @expect_operator 1 = ;
              } else {
                int int ASTINT_GET_TOKEN_OR_FAIL take \1 ")" strcmp 0 == "ast_parsev: error 5" assert_msg ;
                operator_stack "(_PRE" strdup vector_push_back ;
                operand_stack ast_init vector_push_back ;
                center_stack type_idx vector_push_back ;
              }
            } else {
              # Operand as we expect, push it in the operand stack
              @ast ast_init = ;
              ast AST_TYPE take_addr 0 = ;
              ast AST_NAME take_addr tok strdup = ;
              operand_stack ast vector_push_back ;
              @expect_operator 1 = ;
            }
          }
        }
        # Partially rewind the stack so that priority is decreasing
        if expect_operator ! {
          operator_stack operand_stack center_stack ast_rewind_stack ;
        }
      }
    }
  }

  expect_operator "Expect operand" assert_msg ;

  # Ad a final placeholder operator with the weakest possible priority,
  # in order to force the whole stack rewind
  $tmp
  @tmp " " strdup = ;
  operator_stack tmp vector_push_back ;
  center_stack 0 vector_push_back ;
  operator_stack operand_stack center_stack ast_rewind_stack ;
  operator_stack vector_pop_back tmp == "Internal error" assert_msg ;
  tmp free ;
  center_stack vector_pop_back 0 == "Internal error" assert_msg ;

  $res
  @res operand_stack vector_pop_back = ;

  operand_stack vector_size 0 == "Internal error" assert_msg ;
  operator_stack vector_size 0 == "Internal error" assert_msg ;
  center_stack vector_size 0 == "Internal error" assert_msg ;

  operand_stack vector_destroy ;
  operator_stack vector_destroy ;
  center_stack vector_destroy ;

  # "Ending parse\n" 1 platform_log ;

  res ret ;
}

fun ast_parse1 2 {
  $int
  $end_tok
  @int 1 param = ;
  @end_tok 0 param = ;

  $end_toks
  @end_toks 4 vector_init = ;
  end_toks end_tok vector_push_back ;
  $res
  @res int end_toks ast_parsev = ;
  end_toks vector_destroy ;
  res ret ;
}

fun ast_parse2 3 {
  $int
  $end_tok1
  $end_tok2
  @int 2 param = ;
  @end_tok1 1 param = ;
  @end_tok2 0 param = ;

  $end_toks
  @end_toks 4 vector_init = ;
  end_toks end_tok1 vector_push_back ;
  end_toks end_tok2 vector_push_back ;
  $res
  @res int end_toks ast_parsev = ;
  end_toks vector_destroy ;
  res ret ;
}

fun ast_parse3 4 {
  $int
  $end_tok1
  $end_tok2
  $end_tok3
  @int 3 param = ;
  @end_tok1 2 param = ;
  @end_tok2 1 param = ;
  @end_tok3 0 param = ;

  $end_toks
  @end_toks 4 vector_init = ;
  end_toks end_tok1 vector_push_back ;
  end_toks end_tok2 vector_push_back ;
  end_toks end_tok3 vector_push_back ;
  $res
  @res int end_toks ast_parsev = ;
  end_toks vector_destroy ;
  res ret ;
}

fun ast_dump_int 2 {
  $ast
  $depth
  @ast 1 param = ;
  @depth 0 param = ;

  $i
  @i 0 = ;
  while i depth < {
    "  " 1 platform_log ;
    @i i 1 + = ;
  }
  if ast AST_TYPE take 0 == {
    if ast AST_NAME take 0 == {
      "Placeholder operand" 1 platform_log ;
    } else {
      "Operand of type #" 1 platform_log ;
      ast AST_TYPE_IDX take itoa 1 platform_log ;
      ": " 1 platform_log ;
      ast AST_NAME take 1 platform_log ;
    }
    "\n" 1 platform_log ;
  } else {
    ast AST_TYPE take 1 == "ast_dump_int: error 1" assert_msg ;
    "Operator of type #" 1 platform_log ;
    ast AST_TYPE_IDX take itoa 1 platform_log ;
    ": " 1 platform_log ;
    ast AST_NAME take 1 platform_log ;
    "\n" 1 platform_log ;
    ast AST_LEFT take depth 1 + ast_dump_int ;
    ast AST_RIGHT take depth 1 + ast_dump_int ;
  }
}

fun ast_dump 1 {
  0 param 0 ast_dump_int ;
}

fun ast_eval 3 {
  $ast
  $ext
  $ctx
  @ast 2 param = ;
  @ext 1 param = ;
  @ctx 0 param = ;

  # Already evaluated: return directly
  if ast AST_VALUE take 0 != {
    ast AST_VALUE take ret ;
  }

  # Try to hand over to extension: if it succeeds, return directly
  $res
  @res ctx ast ext \2 = ;
  if res 0 != {
    ast AST_VALUE take_addr res = ;
    res ret ;
  }

  # No success so far: we have to try to do something ourselves
  $name
  @name ast AST_NAME take = ;

  # "ast_eval: " 1 platform_log ;
  # name 1 platform_log ;
  # "\n" 1 platform_log ;

  if ast AST_TYPE take 0 == {
    # We have no idea of how to treat an operand in general...
    0 ret ;
  } else {
    # Operator: first evaluate the right operand, and fail if it fails
    $right_value
    @right_value ast AST_RIGHT take ext ctx ast_eval = ;
    if right_value 0 == {
      0 ret ;
    }

    $value
    @value i64_init = ;
    value right_value i64_copy ;
    ast AST_VALUE take_addr value = ;

    # Then execute prefix operators
    if name "!_PRE" strcmp 0 == {
      value i64_lnot ;
      value ret ;
    }

    # Then execute prefix operators
    if name "~_PRE" strcmp 0 == {
      value i64_not ;
      value ret ;
    }

    # Then execute prefix operators
    if name "-_PRE" strcmp 0 == {
      value i64_neg ;
      value ret ;
    }

    # If nothing matched, evaluate left operand and try with infix
    # operators
    $left_value
    @left_value ast AST_LEFT take ext ctx ast_eval = ;
    if left_value 0 == {
      value i64_destroy ;
      ast AST_VALUE take_addr 0 = ;
      0 ret ;
    }
    value left_value i64_copy ;

    if name "&&" strcmp 0 == {
      value right_value i64_land ;
      value ret ;
    }

    if name "||" strcmp 0 == {
      value right_value i64_lor ;
      value ret ;
    }

    if name "&" strcmp 0 == {
      value right_value i64_and ;
      value ret ;
    }

    if name "|" strcmp 0 == {
      value right_value i64_or ;
      value ret ;
    }

    if name "^" strcmp 0 == {
      value right_value i64_xor ;
      value ret ;
    }

    if name "==" strcmp 0 == {
      value right_value i64_eq ;
      value ret ;
    }

    if name "!=" strcmp 0 == {
      value right_value i64_neq ;
      value ret ;
    }

    if name ">=" strcmp 0 == {
      value right_value i64_ge ;
      value ret ;
    }

    if name "<=" strcmp 0 == {
      value right_value i64_le ;
      value ret ;
    }

    if name ">" strcmp 0 == {
      value right_value i64_g ;
      value ret ;
    }

    if name "<" strcmp 0 == {
      value right_value i64_l ;
      value ret ;
    }

    if name "+" strcmp 0 == {
      value right_value i64_add ;
      value ret ;
    }

    if name "-" strcmp 0 == {
      value right_value i64_sub ;
      value ret ;
    }

    if name "*" strcmp 0 == {
      value right_value i64_mul ;
      value ret ;
    }

    if name "/" strcmp 0 == {
      value right_value i64_udiv ;
      value ret ;
    }

    if name "%" strcmp 0 == {
      value right_value i64_umod ;
      value ret ;
    }

    # Nothing matched, so we declare failure
    value i64_destroy ;
    ast AST_VALUE take_addr 0 = ;
    0 ret ;
  }

  0 "ast_eval: should not arrive here" assert_msg ;
}
