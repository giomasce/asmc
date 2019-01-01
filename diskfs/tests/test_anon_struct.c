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

struct S {
    struct {
        int x, y;
    };
    union {
        int z, w;
    };
};

union A {
    int x;
    int y;
    struct {
        char x1;
        int y1;
    };
    struct {
        char x2;
        int y2;
    } other;
    struct {
        char x3;
        int y3;
        struct {
            char x4;
            int y4;
        };
    };
};

// Nothing to test here (for the moment), we just check that the file
// compiles; in line of principle one could add behaviour tests
int test_anon_struct() {
    return 1;
}
