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
import re

TEST_RE = re.compile("Testing ([^ ]*) in file ([^ ]*)... ([^ ]*)!")
MALLOC_RE = re.compile("0 malloc-ed regions were never free-d")

def main():
    test_num = 0
    test_success = 0
    malloc_ok = False
    for line in sys.stdin:
        line = line.strip()
        print(line)
        match = TEST_RE.match(line)
        if match:
            function = match.group(1)
            filename = match.group(2)
            status = match.group(3)
            test_num += 1
            if status == "passed":
                test_success += 1
        if MALLOC_RE.match(line):
            malloc_ok = True

    if test_num == 0:
        print("No test detected, failing...")
        sys.exit(2)
    if test_num != test_success:
        print("Only {} / {} tests succeeded, how bad...".format(test_success, test_num))
        sys.exit(1)
    print("All {} tests succeeded, very good! :-)".format(test_num))

    if not malloc_ok:
        print("Some malloc-ed region was not free-d, that's terrible...")
        sys.exit(1)

if __name__ == '__main__':
    main()
