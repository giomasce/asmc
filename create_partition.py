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
    assert 2 <= len(sys.argv) <= 6
    mbr_filename = sys.argv[1]
    parts_filenames = sys.argv[2:]
    mbr_size = os.stat(mbr_filename).st_size
    parts_sizes = [os.stat(x).st_size for x in parts_filenames]
    assert 0 <= len(parts_sizes) <= 4

    with open(mbr_filename, 'rb') as fmbr:
        mbr = fmbr.read()
    assert len(mbr) == 512
    # Check we are not overwriting anything
    assert mbr[0x1be:0x1fe] == b'\0' * (0x1fe - 0x1be)

    current_lba = 1
    parts_data = b''
    for size in parts_sizes:
        sectors = (size + 511) // 512
        parts_data += b'\x00\xff\xff\xff\x01\xff\xff\xff'
        parts_data += struct.pack('<II', current_lba, sectors)
        current_lba += sectors
    for i in range(4 - len(parts_sizes)):
        parts_data += b'\x00' * 16

    mbr = mbr[:0x1be] + parts_data + mbr[0x1fe:]
    assert len(mbr) == 512

    # Output MBR with partitions
    sys.stdout.buffer.write(mbr)
    for i in range(len(parts_sizes)):
        with open(parts_filenames[i], 'rb') as fin:
            shutil.copyfileobj(fin, sys.stdout.buffer)
            size = parts_sizes[i]
            if size % 512 != 0:
                sys.stdout.buffer.write(b'\0' * (512 - size % 512))

if __name__ == '__main__':
    main()
