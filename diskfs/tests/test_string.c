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

#include <string.h>

int test_strcmp1() {
  return strcmp("hello", "hello") == 0;
}

int test_strcmp2() {
  return strcmp("hello", "world") < 0;
}

int test_strcmp3() {
  return strcmp("hello", "hello world") < 0;
}

int test_strcmp4() {
  return strcmp("hello", "hella") > 0;
}
