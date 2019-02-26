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

const MM0TOK_TYPE_SYMBOL 0
const MM0TOK_TYPE_IDENT 1
const MM0TOK_TYPE_NUMBER 2
const MM0TOK_TYPE_MATH 3

const MM0TOK_SYMB_STAR 1
const MM0TOK_SYMB_COLON 2
const MM0TOK_SYMB_SEMICOLON 3
const MM0TOK_SYMB_OPEN 4
const MM0TOK_SYMB_CLOSED 5
const MM0TOK_SYMB_ARROW 6
const MM0TOK_SYMB_OPENBR 7
const MM0TOK_SYMB_CLOSEDBR 8
const MM0TOK_SYMB_ASSIGN 9

fun mm0tok_init 1 {
  $type
  @type 0 param = ;

  $tok
  @tok SIZEOF_MM0TOK malloc = ;
  tok MM0TOK_TYPE take_addr type = ;
  tok MM0TOK_VALUE take_addr 0 = ;

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

fun mm0_tokenize 1 {
  $filename
  @filename 0 param = ;

  $tokens
  @tokens 4 vector_init = ;

  # TODO: tokenize

  tokens ret ;
}
