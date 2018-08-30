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
typedef char *(*(**foo [][2*3+1])())[];

int;

struct __handles_t {
  void (*platform_write_char)(int fd, char c);
};

char *global_str = "global test string\n";

void putc(char c) {
  struct __handles_t *handles;
  handles = &__handles;
  handles->platform_write_char(1, c);
}

void puts(char *s) {
  while (*s != 0) {
    putc(*s);
    s = s + 1;
  }
}

struct OtherStruct {
  int x, y, z;
};

int init1 = 10 + 20;
struct OtherStruct init2 = { 1000, 2 * 5, 200 / 120};

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
  TEN = 5+3+2,
  ELEVEN
};

int test_array() {
  short x[3];
  *(x+1) = *x = 200;
  *x = 100;
  //*(x+1) = 200;
  *(x+2) = 300;
  //return (x+2)-x;
  return *(1+x);
}

int test_struct() {
  Test2 t;
  t.x = 10;
  t.y = 20;
  t.s.x = 30;
  t.s.y = 40;
  t.s.z = 50;
  Test2 t2;
  t2 = t;
  Test2 *ptr;
  ptr = &t2;
  return ptr->s.y;
}

int printf(char *format, ...) {
  return 0;
}

char *format = "this is a format\n";

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
  int i;
  a = 1;
  for (i = 1; i < 10; i = i + 1) a = a * 2;

  int b, *bptr;
  b = 10;
  bptr = &b;
  *bptr = 20;

  puts("local test string\n");
  puts(global_str);

  return sum_numbers(0) + a + b + (****test_struct)() + test_array() + init1 + init2.y;
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
