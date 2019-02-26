# This file is part of asmc, a bootstrapping OS with minimal seed
# Copyright (C) 2019 Giovanni Mascellani <gio@debian.org>
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

const MM0TOK_TYPE 0
const MM0TOK_VALUE 4
const SIZEOF_MM0TOK 8

const MM0TOK_TYPE_SYMBOL 1
const MM0TOK_TYPE_IDENT 2
const MM0TOK_TYPE_NUMBER 3
const MM0TOK_TYPE_MATH 4

const MM0TOK_SYMB_STAR 1
const MM0TOK_SYMB_COLON 2
const MM0TOK_SYMB_SEMICOLON 3
const MM0TOK_SYMB_OPEN 4
const MM0TOK_SYMB_CLOSED 5
const MM0TOK_SYMB_ARROW 6
const MM0TOK_SYMB_OPENBR 7
const MM0TOK_SYMB_CLOSEDBR 8
const MM0TOK_SYMB_ASSIGN 9

fun mm0tok_init 2 {
  $type
  $value
  @type 1 param = ;
  @value 0 param = ;

  $tok
  @tok SIZEOF_MM0TOK malloc = ;
  tok MM0TOK_TYPE take_addr type = ;
  tok MM0TOK_VALUE take_addr value = ;

  tok ret ;
}

fun mm0tok_destroy 1 {
  $tok
  @tok 0 param = ;

  $type
  @type tok MM0TOK_TYPE take = ;
  if type MM0TOK_TYPE_IDENT == type MM0TOK_TYPE_MATH == || {
    tok MM0TOK_VALUE take free ;
  }
  tok free ;
}

fun mm0tok_dump 1 {
  $tok
  @tok 0 param = ;

  $type
  $value
  @type tok MM0TOK_TYPE take = ;
  @value tok MM0TOK_VALUE take = ;

  if type MM0TOK_TYPE_SYMBOL == {
    if value MM0TOK_SYMB_STAR == { "STAR" 1 platform_log ; ret ; }
    if value MM0TOK_SYMB_COLON == { "COLON" 1 platform_log ; ret ; }
    if value MM0TOK_SYMB_SEMICOLON == { "SEMICOLON" 1 platform_log ; ret ; }
    if value MM0TOK_SYMB_OPEN == { "OPEN" 1 platform_log ; ret ; }
    if value MM0TOK_SYMB_CLOSED == { "CLOSED" 1 platform_log ; ret ; }
    if value MM0TOK_SYMB_ARROW == { "ARROW" 1 platform_log ; ret ; }
    if value MM0TOK_SYMB_OPENBR == { "OPENBR" 1 platform_log ; ret ; }
    if value MM0TOK_SYMB_CLOSEDBR == { "CLOSEDBR" 1 platform_log ; ret ; }
    if value MM0TOK_SYMB_ASSIGN == { "ASSIGN" 1 platform_log ; ret ; }
  }

  if type MM0TOK_TYPE_IDENT == {
    value 1 platform_log ;
    ret ;
  }

  if type MM0TOK_TYPE_NUMBER == {
    value itoa 1 platform_log ;
    ret ;
  }

  if type MM0TOK_TYPE_MATH == {
    # FIXME: add escape here, although this is just for debugging, so
    # who cares
    "$" 1 platform_log ;
    value 1 platform_log ;
    "$" 1 platform_log ;
    ret ;
  }
}

const MM0LEXER_FILENAME 0
const MM0LEXER_FD 4
const MM0LEXER_UNREAD 8
const SIZEOF_MM0LEXER 12

fun mm0lexer_init 1 {
  $filename
  @filename 0 param = ;

  $fd
  @fd filename vfs_open = ;
  if fd ! {
    0 ret ;
  }

  $lexer
  @lexer SIZEOF_MM0LEXER malloc = ;
  lexer MM0LEXER_FILENAME take_addr filename = ;
  lexer MM0LEXER_FD take_addr fd = ;
  lexer MM0LEXER_UNREAD take_addr 0 = ;

  lexer ret ;
}

fun mm0lexer_destroy 1 {
  $lexer
  @lexer 0 param = ;

  lexer MM0LEXER_FD take vfs_close ;
  lexer free ;
}

fun mm0lexer_read 1 {
  $lexer
  @lexer 0 param = ;

  $c
  @c lexer MM0LEXER_UNREAD take = ;
  if c {
    lexer MM0LEXER_UNREAD take_addr 0 = ;
    c ret ;
  } else {
    lexer MM0LEXER_FD take vfs_read ret ;
  }
}

fun mm0lexer_unread 2 {
  $lexer
  $c
  @lexer 1 param = ;
  @c 0 param = ;

  lexer MM0LEXER_UNREAD take ! "mm0lexer_unread: unread buffer already used" assert_msg ;
  lexer MM0LEXER_UNREAD take_addr c = ;
}

fun mm0lexer_read_skip 1 {
  $lexer
  @lexer 0 param = ;

  while 1 {
    $c
    @c lexer mm0lexer_read = ;
    # Check multiline comment
    if c '/' == {
      @c lexer mm0lexer_read = ;
      if c '-' == {
        $slash
        $dash
        @slash 0 = ;
        @dash 0 = ;
        $cont
        @cont 1 = ;
        while cont {
          @c lexer mm0lexer_read = ;
          if slash c '-' == && {
            0 "mm0lexer_read_skip: invalid nested comment" assert_msg ;
          }
          if dash c '/' == && {
            @cont 0 = ;
          }
          @slash 0 = ;
          @dash 0 = ;
          if c '/' == {
            @slash 1 = ;
          }
          if c '-' == {
            @dash 1 = ;
          }
        }
      } else {
        lexer c mm0lexer_unread ;
        '/' ret ;
      }
    } else {
      # Check single line comment
      if c '-' == {
        @c lexer mm0lexer_read = ;
        if c '-' == {
          while c '\n' != {
            @c lexer mm0lexer_read = ;
          }
        } else {
          lexer c mm0lexer_unread ;
          '-' ret ;
        }
      } else {
        if c ' ' == c '\n' == || c '\r' == || c '\t' == || ! {
          c ret ;
        }
      }
    }
  }
}

fun mm0_is_digit 1 {
  $c
  @c 0 param = ;

  '0' c <= c '9' <= && ret ;
}

fun mm0_is_alpha 1 {
  $c
  @c 0 param = ;

  'a' c <= c 'z' <= && 'A' c <= c 'Z' <= && || c '_' == || c '.' == || c '-' == || ret ;
}

fun mm0lexer_get_token 1 {
  $lexer
  @lexer 0 param = ;

  $c
  @c lexer mm0lexer_read_skip = ;

  # End of file
  if c 0xffffffff == {
    0 ret ;
  }

  # Symbol token
  if c '*' == {
    MM0TOK_TYPE_SYMBOL MM0TOK_SYMB_STAR mm0tok_init ret ;
  }
  if c ';' == {
    MM0TOK_TYPE_SYMBOL MM0TOK_SYMB_SEMICOLON mm0tok_init ret ;
  }
  if c '(' == {
    MM0TOK_TYPE_SYMBOL MM0TOK_SYMB_OPEN mm0tok_init ret ;
  }
  if c ')' == {
    MM0TOK_TYPE_SYMBOL MM0TOK_SYMB_CLOSED mm0tok_init ret ;
  }
  if c '{' == {
    MM0TOK_TYPE_SYMBOL MM0TOK_SYMB_OPENBR mm0tok_init ret ;
  }
  if c '}' == {
    MM0TOK_TYPE_SYMBOL MM0TOK_SYMB_CLOSEDBR mm0tok_init ret ;
  }
  if c ':' == {
    @c lexer mm0lexer_read = ;
    if c '=' == {
      MM0TOK_TYPE_SYMBOL MM0TOK_SYMB_ASSIGN mm0tok_init ret ;
    } else {
      lexer c mm0lexer_unread ;
      @c ':' = ;
      MM0TOK_TYPE_SYMBOL MM0TOK_SYMB_COLON mm0tok_init ret ;
    }
  }
  if c '-' == {
    @c lexer mm0lexer_read = ;
    if c '>' == {
      MM0TOK_TYPE_SYMBOL MM0TOK_SYMB_ARROW mm0tok_init ret ;
    } else {
      # Pass it through, so it is picked up by mm0_is_alpha
      lexer c mm0lexer_unread ;
      @c '-' = ;
    }
  }

  # Number token
  if c mm0_is_digit {
    $zero
    @zero c '0' == = ;
    $value
    @value c '0' - = ;
    @c lexer mm0lexer_read = ;
    while c mm0_is_digit {
      zero ! "mm0lexer_get_token: invalid 0 prefix in number token" assert_msg ;
      @value value 10 * c '0' - + = ;
      @c lexer mm0lexer_read = ;
    }
    c mm0_is_alpha ! "mm0lexer_get_token: unexpected alphabetic character in number token" assert_msg ;
    lexer c mm0lexer_unread ;
    MM0TOK_TYPE_NUMBER value mm0tok_init ret ;
  }

  # Identifier token
  if c mm0_is_alpha {
    $size
    $cap
    $value
    @size 0 = ;
    @cap 4 = ;
    @value cap malloc = ;
    while c mm0_is_digit c mm0_is_alpha || {
      # +1 to be sure there is space for the terminator
      if size 1 + cap >= {
        @cap cap 2 * = ;
        @value cap value realloc = ;
      }
      value size + c =c ;
      @size size 1 + = ;
      @c lexer mm0lexer_read = ;
    }
    lexer c mm0lexer_unread ;
    value size + '\0' =c ;
    MM0TOK_TYPE_IDENT value mm0tok_init ret ;
  }

  # Math token
  if c '$' == {
    $size
    $cap
    $value
    @size 0 = ;
    @cap 4 = ;
    @value cap malloc = ;
    @c lexer mm0lexer_read = ;
    $cont
    @cont 1 = ;
    while cont {
      $ignore
      @ignore 0 = ;
      # +1 to be sure there is space for the terminator
      if size 1 + cap >= {
        @cap cap 2 * = ;
        @value cap value realloc = ;
      }
      if c '$' == {
        @c lexer mm0lexer_read = ;
        # If second dollar: no problem, just ignore the first one
        if c '$' != {
         if c '-' == {
           # Math comment: just consume it like a multiline comment
           $dollar
           $dash
           @dollar 0 = ;
           @dash 0 = ;
           $cont2
           @cont2 1 = ;
           while cont2 {
             @c lexer mm0lexer_read = ;
             if dollar c '-' == && {
               0 "mm0lexer_get_token: invalid nested math comment" assert_msg ;
             }
             if dash c '$' == && {
               @cont2 0 = ;
             }
             @dollar 0 = ;
             @dash 0 = ;
             if c '$' == {
               @dollar 1 = ;
             }
             if c '-' == {
               @dash 1 = ;
             }
           }
           @ignore 1 = ;
         } else {
           # End of math
           @cont 0 = ;
         }
        }
      }
      # Only store character if we have not found the end or a comment
      if cont ignore ! && {
        value size + c =c ;
        @size size 1 + = ;
        @c lexer mm0lexer_read = ;
      }
    }
    value size + '\0' =c ;
    MM0TOK_TYPE_MATH value mm0tok_init ret ;
  }

  0 "mm0lexer_get_token: invalid character in input file" assert_msg ;
}

const SIZEOF_MM0TH 0

fun mm0th_init 0 {
  $theory
  @theory SIZEOF_MM0TH malloc = ;

  theory ret ;
}

fun mm0th_destroy 1 {
  $theory
  @theory 0 param = ;

  theory free ;
}

fun mm0_parse 1 {
  $lexer
  @lexer 0 param = ;

  $theory
  @theory mm0th_init = ;

  while 1 {
    $token
    @token lexer mm0lexer_get_token = ;
    if token ! {
      theory ret ;
    }

    # TODO: do stuff
    token mm0tok_dump ;
    " " 1 platform_log ;

    token mm0tok_destroy ;
  }
}

fun mm0_process 1 {
  $filename
  @filename 0 param = ;

  $lexer
  @lexer filename mm0lexer_init = ;

  $theory
  "Parsing MM0 theory: " 1 platform_log ;
  @theory lexer mm0_parse = ;
  "\n" 1 platform_log ;

  # TODO: verify theory

  # Free resources
  theory mm0th_destroy ;
  lexer mm0lexer_destroy ;
}
