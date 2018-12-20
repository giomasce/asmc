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

fun compile_tinycc 0 {
  $filename
  @filename "/disk1/tinycc/tcc.c" = ;

  # Preprocessing
  $ctx
  @ctx ppctx_init = ;
  ctx "ONE_SOURCE" "1" ppctx_define ;
  ctx "USE_SOFTFLOAT" "1" ppctx_define ;
  ctx filename ppctx_set_base_filename ;
  ctx "/disk1/tinycc/softfloat/" ppctx_add_include_path ;
  ctx "/disk1/tinycc/softfloat/include/" ppctx_add_include_path ;
  ctx "/disk1/tinycc/softfloat/8086/" ppctx_add_include_path ;
  #ctx PPCTX_VERBOSE take_addr 0 = ;
  $tokens
  @tokens 4 vector_init = ;
  tokens ctx filename preproc_file ;
  @tokens tokens remove_whites = ;
  #@tokens filename tokenize_file = ;
  "Finished preprocessing\n" 1 platform_log ;
  #tokens print_token_list ;

  # Compilation
  $cctx
  @cctx tokens cctx_init = ;
  cctx cctx_compile ;

  # Debug output
  "TYPES TABLE\n" 1 platform_log ;
  cctx cctx_dump_types ;
  "TYPE NAMES TABLE\n" 1 platform_log ;
  cctx cctx_dump_typenames ;
  "GLOBALS TABLE\n" 1 platform_log ;
  cctx cctx_dump_globals ;

  tokens free_vect_of_ptrs ;
  cctx cctx_destroy ;
  ctx ppctx_destroy ;
}
