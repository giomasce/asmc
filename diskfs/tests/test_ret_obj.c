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

struct len4 {
  int x;
};

struct len8 {
  int x, y;
};

struct len16 {
  int x, y;
  long z;
};

struct len4 ret_len4(int x) {
  struct len4 r;
  r.x = x;
  return r;
}

struct len8 ret_len8(int x, int y) {
  struct len8 r;
  r.x = x;
  r.y = y;
  return r;
}

struct len16 ret_len16(int x, int y, long z) {
  struct len16 r;
  r.x = x;
  r.y = y;
  r.z = z;
  return r;
}

int test_ret_obj() {
  struct len4 r4 = ret_len4(10);
  if (r4.x != 10) return 0;
  struct len8 r8 = ret_len8(20, 30);
  if (r8.x != 20) return 0;
  if (r8.y != 30) return 0;
  struct len16 r16 = ret_len16(100, 200, 1000);
  if (r16.x != 100) return 0;
  if (r16.y != 200) return 0;
  if (r16.z != 1000) return 0;
  return 1;
}
