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

#include <setjmp.h>
#include <stdio.h>

jmp_buf jump_buffer;

int test_setjmp() {
  int res;
  res = setjmp(jump_buffer);
  /*fputs("\n", stderr);
  fputs("EIP: ", stderr);
  fputs(itoa(jump_buffer.eip), stderr);
  fputs("\n", stderr);
  fputs("ESP: ", stderr);
  fputs(itoa(jump_buffer.esp), stderr);
  fputs("\n", stderr);
  fputs("EBP: ", stderr);
  fputs(itoa(jump_buffer.ebp), stderr);
  fputs("\n", stderr);*/
  return res;
}

void func(int x) {
  fputs("called\n", stdout);
  longjmp(jump_buffer, x);
}

int test_setjmp2() {
  int count = 0;
  if (setjmp(jump_buffer) != 3) {
    count = count + 1;
    func(count);
  }
  return 0;
}
