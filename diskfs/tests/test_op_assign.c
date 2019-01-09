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

int test_ptr_assign() {
    int *x = 1000;
    if (x != 1000) return 0;
    if ((x += 50) != 1200) return 0;
    if (x != 1200) return 0;
    long long *y = 10000;
    if (y != 10000) return 0;
    if ((y -= 10) != 9920) return 0;
    if (y != 9920) return 0;
    return 1;
}

int test_int_assign() {
    int x = 1000;
    if (x != 1000) return 0;
    if ((x += 50) != 1050) return 0;
    if (x != 1050) return 0;

    long long y = 10000;
    if (y != 10000) return 0;
    if ((y -= 10) != 9990) return 0;
    if (y != 9990) return 0;

    long long y = 10000;
    if (y != 10000) return 0;
    if ((y <<= 4) != 16 * 10000) return 0;
    if (y != 16 * 10000) return 0;

    // Test that writes smaller than a dword are done correctly
    short ar[10];
    int i;
    for (i = 0; i < 10; i += 1) {
        ar[i] = i;
    }
    ar[5] *= 1;
    for (i = 0; i < 10; i += 1) {
        if (ar[i] != i) return 0;
    }

    return 1;
}

int test_ptr_incdec() {
    int *p = 1000;
    if (p++ != 1000) return 0;
    if (p != 1004) return 0;
    if (p-- != 1004) return 0;
    if (p != 1000) return 0;
    if (++p != 1004) return 0;
    if (p != 1004) return 0;
    if (--p != 1000) return 0;
    if (p != 1000) return 0;
    return 1;
}

int test_int_incdec() {
    int x = 100;
    int y = x++;
    if (x != 101) return 0;
    if (y != 100) return 0;
    x = 100;
    y = ++x;
    if (x != 101) return 0;
    if (y != 101) return 0;
    x = 100;
    y = x--;
    if (x != 99) return 0;
    if (y != 100) return 0;
    x = 100;
    y = --x;
    if (x != 99) return 0;
    if (y != 99) return 0;
    return 1;
}
