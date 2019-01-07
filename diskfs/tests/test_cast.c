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

#include <stddef.h>

typedef struct {
    int x;
} X;

int init[] = {((unsigned char)(10 + 256)) != 10, offsetof(X, x)};

int test_cast() {
    if (init[0] != 0) return 0;
    int x = 1000;
    int y = (unsigned char) x;
    if (y != 232) return 0;
    y = (char) x;
    if (y != -24) return 0;
    void *x = (void*) "test string";
    return 1;
}
