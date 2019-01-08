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

#include <stdio.h>

int test_fputs() {
  int ret;
  ret = fputs("This is a test string\n", stdout);
  return ret >= 0;
}

int test_puts() {
  int ret;
  ret = puts("This is a test string\n");
  return ret >= 0;
}

int test_putchar() {
  int ret;
  ret = putchar('X');
  return ret == 'X';
}

int test_fputc() {
  int ret;
  ret = fputc('X', stdout);
  return ret == 'X';
}

int test_putc() {
  int ret;
  ret = putc('X', stdout);
  return ret == 'X';
}

int test_sprintf() {
    char buf[1024];
    sprintf(buf, "%d %ld %lld", 123, 123L, 123LL);
    if (strcmp(buf, "123 123 123") != 0) return 0;
    sprintf(buf, "%d %ld %lld", -123, -123L, -123LL);
    if (strcmp(buf, "-123 -123 -123") != 0) return 0;
    sprintf(buf, "%u %lu %llu", 123U, 123UL, 123ULL);
    if (strcmp(buf, "123 123 123") != 0) return 0;
    return 1;
}

int test_printf() {
    printf("hello\n");
    char *s = "world";
    printf("hello %s\n", s);
    return 1;
}

int test_sscanf() {
    int i1, i2, i3;
    int res = sscanf("2.3.5", "%d.%d.%d", &i1, &i2, &i3);
    if (i1 != 2) return 0;
    if (i2 != 3) return 0;
    if (i3 != 5) return 0;
    return 1;
}

int test_large_numbers() {
    char buf[1024];
    sprintf(buf, "%d", INT_MAX);
    if (strtol(buf, NULL, 10) != INT_MAX) return 0;
    sprintf(buf, "%d", INT_MIN);
    if (strtol(buf, NULL, 10) != INT_MIN) return 0;
    sprintf(buf, "%u", UINT_MAX);
    if (strtoul(buf, NULL, 10) != UINT_MAX) return 0;
    sprintf(buf, "%ld", LONG_MAX);
    if (strtol(buf, NULL, 10) != LONG_MAX) return 0;
    sprintf(buf, "%ld", LONG_MIN);
    if (strtol(buf, NULL, 10) != LONG_MIN) return 0;
    sprintf(buf, "%lu", ULONG_MAX);
    if (strtoul(buf, NULL, 10) != ULONG_MAX) return 0;
    sprintf(buf, "%lld", LLONG_MAX);
    if (strtol(buf, NULL, 10) != LLONG_MAX) return 0;
    sprintf(buf, "%lld", LLONG_MIN);
    if (strtol(buf, NULL, 10) != LLONG_MIN) return 0;
    sprintf(buf, "%llu", ULLONG_MAX);
    if (strtoul(buf, NULL, 10) != ULLONG_MAX) return 0;
    return 1;
}
