/* This file is part of asmc, a bootstrapping OS with minimal seed
   Copyright (C) 2018 Giovanni Mascellani <gio@debian.org>
   https://gitlab.com/giomasce/asmc

   This program is free software: you can redistribute it and/or modify
   it under the terms of the GNU General Public License as published by
   the Free Software Foundation, either version 3 of the License, or
   (at your option) any later version.

   This program is distributed in the hope that it will be useful,
   but WITHOUT ANY WARRANTY; without even the implied warranty of
   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
   GNU General Public License for more details.

   You should have received a copy of the GNU General Public License
   along with this program.  If not, see <https://www.gnu.org/licenses/>. */

/*#if a * (b + c)
#if a + (b(c,d,e))
#if a + (b((c,d),e))
#if a + b[c]
#endif
#endif
#endif
#endif*/

#define OTHER_TEST 22
TEST_TOK
#define TEST_TOK OTHER_TEST
TEST_TOK
#undef TEST_TOK
TEST_TOK

#define YES
#undef NO

#ifdef NO
#define THREE 3
not_included();
#ifdef YES
not_included();
#endif
#endif
included();
#ifdef NO
not_included();
#else
included();
#ifndef NO
included();
#else
not_included();
#endif
#endif
#ifdef YES
included();
#else
not_included();
#endif

#include <first.h>
#include \
"other.h"

main(argc, argv) {
  int a1;
  int aA;
  int a_a;
  int a;
  a = glob + argc + 1;
  int b;
  b = argv || a;
  int c;
  c = "{hello}[there](world)";
  if (b != 0) {
    b = c + a * a;
  }
  return b;
  int d;
  d = 1;
  return d;
}

test_if() {
  int x;
  if (x == 0) {
    x = 1;
  } else if (x != 2) {
    x = 3;
  } else {
    x = 2;
  }
}

// C++ comment
int glob2;   \
int glob; /* C comment */
