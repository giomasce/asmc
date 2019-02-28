# This file is part of asmc, a bootstrapping OS with minimal seed
# Copyright (C) 2018-2019 Giovanni Mascellani <gio@debian.org>
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

const RUN_MM0 1
const RUN_ASM 0
const RUN_FASM 0
const RUN_C 0
const RUN_MESCC 0
const RUN_MCPP 0
const RUN_TINYCC 1
const TEST_MAP 1
const TEST_INT64 1
const TEST_C 1

const USE_TRIVIAL_MALLOC 0
const USE_SIMPLE_MALLOC 0
const USE_CHECKED_MALLOC 0
const USE_KMALLOC 1

const USE_SIMPLE_MAP 0
const USE_AVL_MAP 0
const USE_RB_MAP 1

fun main 0 {
  "Memory break after entering main: " log ;
  0 platform_allocate itoa log ;
  "\n" log ;

  $compile_mm0
  $compile_asm
  $compile_int64
  $compile_c
  @compile_mm0 0 = ;
  @compile_asm 0 = ;
  @compile_int64 0 = ;
  @compile_c 0 = ;
  if RUN_MM0 {
    @compile_mm0 1 = ;
  }
  if RUN_ASM RUN_FASM || {
    @compile_asm 1 = ;
  }
  if RUN_C RUN_MCPP || RUN_TINYCC || TEST_C || {
    @compile_c 1 = ;
  }
  if TEST_INT64 {
    @compile_int64 1 = ;
  }
  if compile_c {
    @compile_int64 1 = ;
  }
  if compile_int64 {
    @compile_asm 1 = ;
  }

  "Compiling utils.g... " log ;
  "utils.g" platform_g_compile ;
  "done!\n" log ;

  if USE_TRIVIAL_MALLOC {
    "Compiling triv_malloc.g... " log ;
    "triv_malloc.g" platform_g_compile ;
    "done!\n" log ;
  }

  if USE_SIMPLE_MALLOC {
    "Compiling simple_malloc.g... " log ;
    "simple_malloc.g" platform_g_compile ;
    "done!\n" log ;
  }

  if USE_CHECKED_MALLOC {
    "Compiling check_malloc.g... " log ;
    "check_malloc.g" platform_g_compile ;
    "done!\n" log ;
  }

  if USE_KMALLOC {
    "Compiling kmalloc.g... " log ;
    "kmalloc.g" platform_g_compile ;
    "done!\n" log ;
  }

  "Compiling malloc_utils.g... " log ;
  "malloc_utils.g" platform_g_compile ;
  "done!\n" log ;

  "Compiling vector.g... " log ;
  "vector.g" platform_g_compile ;
  "done!\n" log ;

  if USE_SIMPLE_MAP {
    "Compiling map.g... " log ;
    "map.g" platform_g_compile ;
    "done!\n" log ;
  }

  if USE_AVL_MAP {
    "Compiling avl_map.g... " log ;
    "avl_map.g" platform_g_compile ;
    "done!\n" log ;
  }

  if USE_RB_MAP {
    "Compiling rb_map.g... " log ;
    "rb_map.g" platform_g_compile ;
    "done!\n" log ;
  }

  if TEST_MAP {
    "Compiling map_test.g... " log ;
    "map_test.g" platform_g_compile ;
    "done!\n" log ;
  }

  "Compiling utils2.g... " log ;
  "utils2.g" platform_g_compile ;
  "done!\n" log ;

  "Compiling atapio.g... " log ;
  "atapio.g" platform_g_compile ;
  "done!\n" log ;

  "Compiling diskfs.g... " log ;
  "diskfs.g" platform_g_compile ;
  "done!\n" log ;

  "Compiling debugfs.g... " log ;
  "debugfs.g" platform_g_compile ;
  "done!\n" log ;

  "Compiling ramfs.g... " log ;
  "ramfs.g" platform_g_compile ;
  "done!\n" log ;

  "Compiling mbr.g... " log ;
  "mbr.g" platform_g_compile ;
  "done!\n" log ;

  "Compiling vfs.g... " log ;
  "vfs.g" platform_g_compile ;
  "done!\n" log ;

  "Compiling vfs_utils.g... " log ;
  "vfs_utils.g" platform_g_compile ;
  "done!\n" log ;

  if compile_mm0 {
    "Compiling mm0.g... " log ;
    "mm0.g" platform_g_compile ;
    "done!\n" log ;
  }

  if compile_asm {
    #"Memory break before ASM assembler compilation: " log ;
    #0 platform_allocate itoa log ;
    #"\n" log ;

    "Compiling asm_regs.g... " log ;
    "asm_regs.g" platform_g_compile ;
    "done!\n" log ;

    "Compiling asm_preproc.g... " log ;
    "asm_preproc.g" platform_g_compile ;
    "done!\n" log ;

    "Compiling asm_opcodes.g... " log ;
    "asm_opcodes.g" platform_g_compile ;
    "done!\n" log ;

    "Compiling asm_compile.g... " log ;
    "asm_compile.g" platform_g_compile ;
    "done!\n" log ;

    #"Memory break after ASM assembler compilation: " log ;
    #0 platform_allocate itoa log ;
    #"\n" log ;
  }

  if compile_int64 {
    "Compiling int64.g... " log ;
    "int64.g" platform_g_compile ;
    "done!\n" log ;

    "Compiling int64_div.g... " log ;
    "int64_div.g" platform_g_compile ;
    "done!\n" log ;
  }

  if compile_c {
    "Compiling c_utils.g... " log ;
    "c_utils.g" platform_g_compile ;
    "done!\n" log ;

    "Compiling c_ast.g... " log ;
    "c_ast.g" platform_g_compile ;
    "done!\n" log ;

    "Compiling c_preproc.g... " log ;
    "c_preproc.g" platform_g_compile ;
    "done!\n" log ;

    "Compiling c_compile.g... " log ;
    "c_compile.g" platform_g_compile ;
    "done!\n" log ;

    "Compiling c_test.g... " log ;
    "c_test.g" platform_g_compile ;
    "done!\n" log ;
  }

  if RUN_MESCC {
    "Compiling mescc_hex2.g... " log ;
    "mescc_hex2.g" platform_g_compile ;
    "done!\n" log ;

    "Compiling mescc_m1.g... " log ;
    "mescc_m1.g" platform_g_compile ;
    "done!\n" log ;

    "Compiling mescc_m2.g... " log ;
    "mescc_m2.g" platform_g_compile ;
    "done!\n" log ;
  }

  "Memory break after compilers compilation: " log ;
  0 platform_allocate itoa log ;
  "\n" log ;

  if TEST_MAP {
    0 "map_test" platform_get_symbol \0 ;
  }

  "Initializing Virtual File System...\n" log ;
  0 "vfs_init" platform_get_symbol \0 ;
  "Virtual File System initialized!\n" log ;

  if compile_int64 {
    "Initializing support for int64...\n" log ;
    0 "int64_init" platform_get_symbol \0 ;
    "Support for int64 initialized!\n" log ;
  }

  "Initializing resolve_symbol_ext...\n" log ;
  0 "init_resolve_symbol_ext" platform_get_symbol \0 ;
  "done!\n" log ;

  # Determine if there is an actual script
  $script_file
  @script_file "/init/script.g" 0 "vfs_open" platform_get_symbol \1 = ;
  $have_script
  @have_script script_file 0 "vfs_read" platform_get_symbol \1 0xffffffff != = ;
  script_file 0 "vfs_close" platform_get_symbol \1 ;

  if have_script {
    "Compiling script.g... " log ;
    "script.g" platform_g_compile ;
    "done!\n" log ;

    "Running the script...\n" log ;
    0 "run_script" platform_get_symbol \0 ;
  } else {
    "No script, running the usual payload...\n" log ;

    if RUN_MM0 {
      "/disk1/mm0/set.mm0" 0 "mm0_process" platform_get_symbol \1 ;
    }

    if RUN_ASM {
      "/init/test.asm" 0 "parse_asm" platform_get_symbol \1 ;
    }

    if RUN_FASM {
      "Compiling fasm.g... " log ;
      "fasm.g" platform_g_compile ;
      "done!\n" log ;

      0 "compile_fasm" platform_get_symbol \0 ;
    }

    if RUN_C {
      "/disk1/tests/test.c" 0 "parse_c" platform_get_symbol \1 ;
    }

    if TEST_INT64 {
      0 "int64_test" platform_get_symbol \0 ;
      0 "int64_test_div" platform_get_symbol \0 ;
    }

    if TEST_C {
      0 "c_run_testcases" platform_get_symbol \0 ;
    }

    if RUN_MESCC {
      0 "hex2_test" platform_get_symbol \0 ;
      0 "m1_test" platform_get_symbol \0 ;
      0 "m2_test" platform_get_symbol \0 ;
      0 "m2_test_full_compilation" platform_get_symbol \0 ;
    }

    if RUN_MCPP {
      "Compiling mcpp.g... " log ;
      "mcpp.g" platform_g_compile ;
      "done!\n" log ;

      0 "compile_mcpp" platform_get_symbol \0 ;
    }

    if RUN_TINYCC {
      "Compiling tinycc.g... " log ;
      "tinycc.g" platform_g_compile ;
      "done!\n" log ;

      0 "compile_tinycc" platform_get_symbol \0 ;
    }
  }

  if compile_int64 {
    "Destroying support for int64... " log ;
    0 "int64_destroy" platform_get_symbol \0 ;
    "done!\n" log ;
  }

  "Destroying resolve_symbol_ext... " log ;
  0 "destroy_resolve_symbol_ext" platform_get_symbol \0 ;
  "done!\n" log ;

  "Destroying Virtual File System... " log ;
  0 "vfs_destroy" platform_get_symbol \0 ;
  "done!\n" log ;

  "Destroying debugfs... " log ;
  0 "debugfs_deinit" platform_get_symbol \0 ;
  "done!\n" log ;

  "Memory break before exiting main: " log ;
  0 platform_allocate itoa log ;
  "\n" log ;

  0 "malloc_stats" platform_get_symbol \0 ;
}
