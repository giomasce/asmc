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

int main2();

int main(int argc, char **argv) {
  return main2();
}

int do_sum(int x, char y) {
  return x+y;
}

int sum_numbers(int x) {
  int i;
  int sum;
  i = 0;
  sum = 0;
  while (i < 200) {
    i = i + 1;
    if (i == 1) continue;
    sum = do_sum(sum, i);
    int x;
    if (i == 100) break;
  }
  return sum;
}

int main2() {
  "test string";
  int a;
  return sum_numbers(0);
}

/*
int sub(int x, int y);

int main(int argc, char **argv) {
  int z = sub(argc, 1);
  return z;
}

int sub(int x, int y) {
  return x - y;
}
*/
