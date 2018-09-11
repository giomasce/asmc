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

fun compile_fasm 0 {
  $filename
  @filename "/disk1/fasm/fasm.asm" = ;

  $ctx
  @ctx asmctx_init = ;
  $fd
  @fd filename vfs_open = ;
  fd "compile_fasm: file does not exist" assert_msg ;
  ctx fd asmctx_set_fd ;
  ctx asmctx_compile ;
  fd vfs_close ;
  ctx asmctx_destroy ;
}
