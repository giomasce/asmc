/* This file is part of asmc, a bootstrapping OS with minimal seed
   Copyright (C) 2018-2019 Giovanni Mascellani <gio@debian.org>
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

#include <stdbool.h>

int my_abs(int x) {
    return x >= 0 ? x : -x;
}

int test_ternary() {
    if (my_abs(0) != 0) return 0;
    if (my_abs(1) != 1) return 0;
    if (my_abs(100) != 100) return 0;
    if (my_abs(-1) != 1) return 0;
    if (my_abs(-100) != 100) return 0;
    return 1;
}

int test_ternary_ptr() {
    char x = 'x';
    char y = 'y';
    if (*(1 ? &x : &y) != 'x') return 0;
    if (*(0 ? &x : &y) != 'y') return 0;
    return 1;
}

int test_ternary_void() {
    int x = 0;
    int y = 0;
    1 ? x++ : y++;
    if (x != 1) return 0;
    if (y != 0) return 0;
    0 ? x++ : y++;
    if (x != 1) return 0;
    if (y != 1) return 0;
    return 1;
}

int test_bool() {
    bool x = 0;
    if (x != 0) return 0;
    if (x == 1) return 0;
    if (x == 100) return 0;
    x = 1;
    if (x == 0) return 0;
    if (x != 1) return 0;
    if (x == 100) return 0;
    x = 100;
    if (x == 0) return 0;
    if (x != 1) return 0;
    if (x == 100) return 0;
    return 1;
}
