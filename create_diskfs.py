#!/usr/bin/env python3
# -*- coding: utf-8 -*-

# This file is part of asmc, a bootstrapping OS with minimal seed
# Copyright (C) 2018 Giovanni Mascellani <gio@debian.org>
# https://gitlab.com/giomasce/asmc

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
import os
import struct
import shutil

def main():
    assert len(sys.argv) % 2 == 1
    file_num = (len(sys.argv) - 1) // 2
    table_len = 0
    files_len = 0
    names = []
    sizes = []
    starts = []

    for i in range(file_num):
        name = sys.argv[2*i+1].encode('ascii')
        data_filename = sys.argv[2*i+2]
        data_size = os.stat(data_filename).st_size

        names.append(name)
        sizes.append(data_size)
        starts.append(files_len)

        table_len += 9 + len(name)
        files_len += data_size

    sys.stdout.buffer.write(b'DISKFS  ')
    # 8 bytes for DISKFS and one another for the final null
    table_len += 9

    for i in range(file_num):
        sys.stdout.buffer.write(names[i])
        sys.stdout.buffer.write(b'\0')
        sys.stdout.buffer.write(struct.pack('!II', starts[i] + table_len, sizes[i]))

    sys.stdout.buffer.write(b'\0')

    for i in range(file_num):
        with open(sys.argv[2*i+2], 'rb') as fin:
            shutil.copyfileobj(fin, sys.stdout.buffer)

if __name__ == '__main__':
    main()
