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

const TINYCC_LOAD_TOKENS 0

fun compile_tinycc 0 {
  $filename
  @filename "/disk1/run_tcc.c" = ;

  # Preprocessing
  $ctx
  @ctx ppctx_init = ;
  $tokens

  if TINYCC_LOAD_TOKENS {
    @tokens load_token_list_from_diskfs = ;
  } else {
    "Preprocessing tinycc...\n" log ;
    ctx "__ASMC_COMP__" "1" ppctx_define ;
    ctx filename ppctx_set_base_filename ;
    ctx "/disk1/tinycc/" ppctx_add_include_path ;
    ctx "/disk1/tinycc-aux/" ppctx_add_include_path ;
    ctx "/disk1/tinycc/softfloat/" ppctx_add_include_path ;
    ctx "/disk1/tinycc/softfloat/include/" ppctx_add_include_path ;
    ctx "/disk1/tinycc/softfloat/8086/" ppctx_add_include_path ;
    ctx PPCTX_VERBOSE take_addr 1 = ;
    @tokens 4 vector_init = ;
    tokens ctx filename preproc_file ;
    @tokens tokens remove_whites = ;
    @tokens tokens collapse_strings = ;
    "Finished preprocessing tinycc!\n" log ;
    #tokens dump_token_list_to_debugfs ;
  }

  # Compilation
  $cctx
  @cctx tokens cctx_init = ;
  cctx CCTX_VERBOSE take_addr 1 = ;
  cctx CCTX_DEBUG take_addr 0 = ;
  #cctx CCTX_DEBUG_AFTER take_addr 1000 "..................................................................................................................................................................................." strlen 1 - * = ;
  "Compiling tinycc...\n" log ;
  cctx cctx_compile ;
  "Finished compiling tinycc!\n" log ;

  cctx cctx_print_stats ;

  # Try to execute the code
  "Executing compiled tinycc...\n" log ;
  $main_global
  @main_global cctx "_start" cctx_get_global = ;
  $main_addr
  @main_addr main_global GLOBAL_LOC take = ;
  $arg
  @arg "_main" = ;
  $res
  @res @arg 1 main_addr \2 = ;
  "tinycc returned " log ;
  res itoa log ;
  "\n" log ;

  # Dump some test file
  # "/ram/ipxe/main.o" "main.o" debugfs_copy_file ;
  # "/ram/ipxe/main.o" dump_debug ;
  # "/ram/ipxe/init.o" dump_debug ;
  # "/ram/ipxe/vsprintf.o" dump_debug ;
  # "/ram/ipxe/ipxe.o" dump_debug ;

  tokens free_vect_of_ptrs ;
  cctx cctx_destroy ;
  ctx ppctx_destroy ;
}
