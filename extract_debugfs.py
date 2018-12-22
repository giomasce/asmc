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

def main():
    assert len(sys.argv) == 2
    disk_filename = sys.argv[1]
    with open(disk_filename, 'rb') as fdisk:
        mbr = fdisk.read(512)
        assert len(mbr) == 512
        parts_data = mbr[0x1be:0x1fe]
        for i in range(4):
            part_data = parts_data[16*i:16*(i+1)]
            if part_data[4] == b'\x00':
                continue
            start_lba, sectors = struct.unpack('<II', part_data[8:])
            fdisk.seek(start_lba * 512, os.SEEK_SET)
            magic = fdisk.read(8)
            if magic == b'DEBUGFS ':
                print('Debug partition found!')
                current_lba = start_lba + 1
                fdisk.seek(current_lba * 512, os.SEEK_SET)
                while True:
                    filename_raw = fdisk.read(512)
                    current_lba += 1
                    filename = bytes([b for b in filename_raw if b != 0]).decode('ascii')
                    if filename == '':
                        break
                    with open('debugfs/{}'.format(filename), 'wb') as fout:
                        while True:
                            block = fdisk.read(512)
                            current_lba += 1
                            if block == b'\x00' * 512:
                                break
                            fout.write(bytes([b for b in block if b != 0]))
                    print(filename)

if __name__ == '__main__':
    main()
