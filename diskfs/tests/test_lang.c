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

// Test from http://www.unixwiz.net/techtips/reading-cdecl.html
typedef char *(*(**foo [][2*3+1])())[];

int;

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
  THREE,
  FOUR,
  TEN = 5+3+2,
  ELEVEN
};

int test_false(void) {
  return 0;
}

int test_true(void) {
  return 1;
}

int do_sum(int x, char y) {
  return x+y;
}

int test_while() {
  int i;
  int sum;
  i = 0;
  sum = 0;
  while (i < 200) {
    i = i + 1;
    if (i == 10) continue;
    sum = do_sum(sum, i);
    if (i == 100) break;
  }
  return sum;
}

int test_do_while() {
    int i;
    int sum;
    i = 0;
    sum = 0;
    do {
        i = i + 1;
        if (i == 10) continue;
        sum = do_sum(sum, i);
        if (i == 100) break;
    } while (i < 200 && i != 0);
    return sum;
}

int test_for() {
  int i;
  int sum;
  sum = 0;
  for (i = 0; i < 200; i = i + 1) {
    if (i == 10) continue;
    sum = do_sum(sum, i);
    if (i == 100) break;
  }
  for (;;) {
      break;
  }
  return sum;
}

int test_array() {
  short x[3];
  *(x+1) = *x = 200;
  *x = 100;
  //*(x+1) = 200;
  *(x+2) = 300;
  x[3] = 400;
  if (3[x] != 400) return 0;
  //return (x+2)-x;
  return x[1];
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

extern int glob2;

// C++ comment
int glob; /* C comment */
int glob2;   \
Test2 glob3;
Test3 glob4;

int test_enum() {
  return ELEVEN;
}

char *global_str = "global test string\n" "other piece\n";

int test_strings() {
  if (*global_str != 'g') return 0;
  if (*"local test string\n" != 'l') return 0;
  return 1;
}

#define YES
#undef NO
#define TEST 1 < 2

int test_define() {
  int i = 0;
#if defined(NO)
  return 0;
#ifdef YES
  return 0;
#endif
#endif
  i = i + 1;
#if !defined(YES)
  return 0;
#else
  i = i + 1;
#ifndef NO
  i = i + 1;
#else
  return 0;
#endif
#endif
#if defined(YES)
  i = i + 1;
#else
 return 0;
#endif
#if TEST
 i = i + 1;
#endif
#if !TEST
 return 0;
#endif
 return i;
}

#undef YES
#undef NO
#undef TEST

int test_extension() {
  char c = -1;
  return c;
}

int test_unary() {
  if (+0 != 0) return 0;
  if (+1 != 1) return 0;
  if (+2 != 2) return 0;
  if (-0 != 0) return 0;
  if (-1 != 0xffffffff) return 0;
  if (-2 != 0xfffffffe) return 0;
  if (~0 != 0xffffffff) return 0;
  if (~1 != 0xfffffffe) return 0;
  if (~2 != 0xfffffffd) return 0;
  if (-0 != 0-0) return 0;
  if (-1 != 0-1) return 0;
  if (-2 != 0-2) return 0;
  if (!0 != 1) return 0;
  if (!1 != 0) return 0;
  if (!2 != 0) return 0;
  return 1;
}

int test_shifts() {
  int s1 = 128;
  unsigned int u1 = 128;
  int s2 = -128;
  if (s1 << 2 != 512) return 0;
  if (s1 >> 2 != 32) return 0;
  if (u1 << 2 != 512) return 0;
  if (u1 >> 2 != 32) return 0;
  if (s2 << 2 != -512) return 0;
  if (s2 >> 2 != -32) return 0;
  return 1;
}

int side_effect(int *val, int ret) {
  *val = 2;
  return ret;
}

int test_logic() {
  int val = 1;
  if ((0 && side_effect(&val, 0)) != 0) return 0;
  if ((1 && 0) != 0) return 0;
  if ((0 && side_effect(&val, 2)) != 0) return 0;
  if ((2 && 3) != 1) return 0;
  if ((0 || 0) != 0) return 0;
  if ((1 || side_effect(&val, 0)) != 1) return 0;
  if ((0 || 2) != 1) return 0;
  if ((2 || side_effect(&val, 3)) != 1) return 0;
  return val;
}

int test_switch() {
    int i;
    int j = 0;
    for (i = 0; i < 10; i++) {
        switch (i) {
            return 0;
        case 1:
            j++;
            break;
            return 0;
        case THREE:
        case FOUR:
        case 5:
            j += 2;
        case 7:
            j++;
            break;
            return 0;
        case 1:
        case 6:
            break;
        case 100:
            return 0;
        default:
            j += 10;
        }
    }
    return j == 51;
}

int test_goto() {
    int x = 0;
    // Check that empty statements are accepted
    ;
    goto test_lab;
    return 0;
 test_lab2:
    if (x != 1) return 0;
    goto finish;
    int y = 13;
 test_lab:
    x = 1;
    if (0) {
        goto test_lab2;
    } else {
        goto test_lab2;
    }
 finish:
    return 1;
}

struct struct_size {
    int x;
    char y;
};

int test_sizeof() {
    int s = sizeof(int);
    if (s != 4) return 0;
    int x = 10;
    // Check that side effect do not happen (i.e., expression is not
    // evaluated)
    s = sizeof --x;
    if (s != 4) return 0;
    if (x != 10) return 0;
    s = sizeof(test_sizeof());
    if (s != 4) return 0;

    if (sizeof(char) != 1) return 0;
    if (sizeof(char*) != 4) return 0;
    if (sizeof(char[10]) != 10) return 0;

    char x[10];
    if (sizeof(x) != 10) return 0;
    if (sizeof(x[0]) != 1) return 0;

    if (sizeof(struct struct_size) != 8) return 0;

    short static_sizeof[sizeof s];
    if (sizeof static_sizeof != 8) return 0;

    return 1;
}

int test_comma() {
    int x = 2;
    int y = (x++, 10);
    if (x != 3) return 0;
    if (y != 10) return 0;
    return 1;
}

int array_without_length[] = {1, 2, 3, ' '};
char string_without_length[] = "test\n\f\r";
char string_in_array_form[] = {1, 2, 3};
char strings[][6] = { "one", "two", "three" };

int test_initializers() {
    if (sizeof(array_without_length) != 4*4) return 0;
    if (sizeof(string_without_length) != 8) return 0;
    if (sizeof(string_in_array_form) != 3) return 0;
    if (string_without_length[0] != 't') return 0;
    if (string_without_length[4] != '\n') return 0;
    if (string_without_length[6] != '\r') return 0;
    if (string_without_length[7] != 0) return 0;
    return 1;
}
