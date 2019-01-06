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

#include <stdarg.h>

int compute_int_sum(int count, ...) {
    va_list v;
    va_start(v, count);
    int i;
    int sum = 0;
    for (i = 0; i < count; i++) {
        sum += va_arg(v, int);
    }
    va_end(v);
    return sum;
}

long compute_long_sum(int count, ...) {
    va_list v;
    va_start(v, count);
    int i;
    long sum = 0;
    for (i = 0; i < count; i++) {
        sum += va_arg(v, long);
    }
    va_end(v);
    return sum;
}

int compute_int_sum_twice(int count, ...) {
    va_list v;
    va_list v2;
    va_start(v, count);
    va_copy(v2, v);
    int i;
    int sum = 0;
    for (i = 0; i < count; i++) {
        sum += va_arg(v, int);
    }
    va_end(v);
    for (i = 0; i < count; i++) {
        sum += va_arg(v2, int);
    }
    va_end(v2);
    return sum;
}

int test_stdarg() {
    if (compute_int_sum(5, 1, 2, 3, 4, 5) != 15) return 0;
    if (compute_long_sum(5, 1l, 2l, 3l, 4l, 5l) != 15) return 0;
    if (compute_int_sum_twice(5, 1, 2, 3, 4, 5) != 30) return 0;
    return 1;
}
