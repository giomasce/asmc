#!/usr/bin/env python3
# -*- coding: utf-8 -*-

# This file is part of asmc, a bootstrapping OS with minimal seed
# Copyright (C) 2018 Giovanni Mascellani <gio@debian.org>
# https://gitlab.com/giomasce/asmc

# This file was ported from files in M2-Planet,
# which have the following copyright notices:
# Copyright (C) 2016 Jeremiah Orians

# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.

# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.

# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <https://www.gnu.org/licenses/>.

import sys
import codecs
import os

def main():
    for line in sys.stdin:
        line = line.strip()
        if line.startswith("--DUMP--"):
            filename = line.split(' ', 1)[1]
            print("> dumping {}".format(filename))
            assert filename[0] == '/'
            filename = filename[1:]
            line = sys.stdin.readline().strip()
            content = codecs.decode(line.replace(' ', ''), 'hex')
            #print(repr(content))
            dump_path = os.path.join("dump", filename)
            os.makedirs(os.path.dirname(dump_path), exist_ok=True)
            with open(dump_path, 'wb') as fout:
                fout.write(content)
            line = sys.stdin.readline().strip()
            assert line == '--END_DUMP--'
        else:
            print(line)

if __name__ == '__main__':
    main()
