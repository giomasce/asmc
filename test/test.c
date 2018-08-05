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

typedef unsigned int size_t;
typedef int ssize_t;

// Test from http://www.unixwiz.net/techtips/reading-cdecl.html
typedef char *(*(**foo [0][8])())[];

int;

struct OtherStruct {
  int x, y, z;
};

typedef struct Test {
  int x:5, y:6;
  struct OtherStruct s;
  char z:0;
  struct Test *ptr;
} Test2, *TestPtr, **TestPtrPtr;

typedef union Test {
  int x, y;
  struct OtherStruct s;
  char z;
  struct Test *ptr;
} Test3;

enum Enum {
  ZERO,
  ONE,
  TWO,
  TEN = 10,
  ELEVEN
};

int printf(char *format, ...) {
  return 0;
}

char *format;

void test_printf() {
  printf(format, 10);
}

extern int glob2;

// C++ comment
int glob; /* C comment */
int glob2;   \
Test2 glob3;
Test3 glob4;

int test_enum() {
  return ZERO;
  return ONE;
  return TWO;
  return TEN;
  return ELEVEN;
}

#include <first.h>
#include \
"other.h"

int main() {
  "test string";
  int a;
  Test2 loc2;
  Test3 loc3;
  return sum_numbers(0);
}

#ifdef __UNDEF
int f(char g(unsigned int)) {
  return 0;
}

int test, test2;
unsigned char x, y, z;
char *ptr, arr[8];
short arr2[3];
char *arr3[10];
char *(arr4[10]);
char (*arr5)[10];

void (*main_ptr)(int argc, char *argv[], char*);

int main(int other_name, char **);

int main3(int argc, char **argv) {
  char c;
  int x1;
  unsigned int x2;

  c = 4;

  while (0) {
    30;
  }

  if (1) x2;
  else {
    if (2) {
      return 3;
    } else {
      return 4;
    }
  }

  /*2+2;
  2-2;
  2*2;
  2/2;
  2%2;*/

  //2 < (2+2/2);

  2+x1+x;

  int arr[10];

  /*x1;
  c;
  c+x1+x2;
  //"hello";
  main_ptr;*/

  return 20+1+1;
}

int main(int, char**);

int main2() {
  short x;
  return x;
}

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

#endif
