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

long long square(long long x) {
    return x*x;
}

int test_llong() {
    long long x = 10;
    int y = x;
    return y == 10;
}

int test_llong_sum() {
    long long x = 10;
    long long y = 20;
    long long z = x + y;
    return z == 30;
}

int test_llong_ops() {
    unsigned long long x = 4000000000;
    unsigned long long y = 4000000000;
    unsigned long long z = x + y;
    unsigned long long w = 2 * x;
    if (z != w) return 0;
    long long sq = square(2);
    if (sq != 4) return 0;
    sq = square(2000000000);
    if (sq != 4000000000000000000ULL) return 0;
    if ((unsigned long long) sq == 2643460096) return 0;
    if ((unsigned) sq != 2643460096) return 0;
    return 1;
}

int test_one_udiv(unsigned long long x, unsigned long long y) {
    unsigned long long d = x / y;
    unsigned long long m = x % y;
    if (x != y * d + m) return 0;
    if (m >= y) return 0;
    return 1;
}

int test_one_sdiv(long long x, long long y) {
    long long d = x / y;
    long long m = x % y;
    long long y_abs = y >= 0 ? y : -y;
    if (x != y * d + m) return 0;
    if (m >= y_abs) return 0;
    if (m <= -y_abs) return 0;
    return 1;
}

int test_llong_mul_div() {
    if (!test_one_udiv(23472873523784, 23946287)) return 0;
    if (!test_one_udiv(23472873523784, 239)) return 0;
    if (!test_one_udiv(23472873523784, 23927428734572354)) return 0;

    if (!test_one_sdiv(23472873523784, 23946287)) return 0;
    if (!test_one_sdiv(23472873523784, 239)) return 0;
    if (!test_one_sdiv(23472873523784, 23927428734572354)) return 0;

    if (!test_one_sdiv(-23472873523784, 23946287)) return 0;
    if (!test_one_sdiv(-23472873523784, 239)) return 0;
    if (!test_one_sdiv(-23472873523784, 23927428734572354)) return 0;

    if (!test_one_sdiv(23472873523784, -23946287)) return 0;
    if (!test_one_sdiv(23472873523784, -239)) return 0;
    if (!test_one_sdiv(23472873523784, -23927428734572354)) return 0;

    if (!test_one_sdiv(-23472873523784, -23946287)) return 0;
    if (!test_one_sdiv(-23472873523784, -239)) return 0;
    if (!test_one_sdiv(-23472873523784, -23927428734572354)) return 0;

    return 1;
}
