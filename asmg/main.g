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

const RUN_ASM 0
const RUN_FASM 0
const RUN_C 0
const RUN_MESCC 0
const RUN_MCPP 0
const RUN_TINYCC 0
const TEST_C 1

const USE_TRIVIAL_MALLOC 0
const USE_SIMPLE_MALLOC 0
const USE_CHECKED_MALLOC 0
const USE_KMALLOC 1

const USE_SIMPLE_MAP 0
const USE_AVL_MAP 1

fun main 0 {
  "Hello, G!\n" 1 platform_log ;

  "Memory break after entering main: " 1 platform_log ;
  0 platform_allocate itoa 1 platform_log ;
  "\n" 1 platform_log ;

  "Compiling utils.g... " 1 platform_log ;
  "utils.g" platform_g_compile ;
  "done!\n" 1 platform_log ;

  if USE_TRIVIAL_MALLOC {
    "Compiling triv_malloc.g... " 1 platform_log ;
    "triv_malloc.g" platform_g_compile ;
    "done!\n" 1 platform_log ;
  }

  if USE_SIMPLE_MALLOC {
    "Compiling simple_malloc.g... " 1 platform_log ;
    "simple_malloc.g" platform_g_compile ;
    "done!\n" 1 platform_log ;
  }

  if USE_CHECKED_MALLOC {
    "Compiling check_malloc.g... " 1 platform_log ;
    "check_malloc.g" platform_g_compile ;
    "done!\n" 1 platform_log ;
  }

  if USE_KMALLOC {
    "Compiling kmalloc.g... " 1 platform_log ;
    "kmalloc.g" platform_g_compile ;
    "done!\n" 1 platform_log ;
  }

  "Compiling malloc_utils.g... " 1 platform_log ;
  "malloc_utils.g" platform_g_compile ;
  "done!\n" 1 platform_log ;

  "Compiling vector.g... " 1 platform_log ;
  "vector.g" platform_g_compile ;
  "done!\n" 1 platform_log ;

  if USE_SIMPLE_MAP {
    "Compiling map.g... " 1 platform_log ;
    "map.g" platform_g_compile ;
    "done!\n" 1 platform_log ;
  }

  if USE_AVL_MAP {
    "Compiling avl_map.g... " 1 platform_log ;
    "avl_map.g" platform_g_compile ;
    "done!\n" 1 platform_log ;
  }

  # "Compiling map_test.g... " 1 platform_log ;
  # "map_test.g" platform_g_compile ;
  # "done!\n" 1 platform_log ;

  # 0 "map_test" platform_get_symbol \0 ;

  "Compiling utils2.g... " 1 platform_log ;
  "utils2.g" platform_g_compile ;
  "done!\n" 1 platform_log ;

  "Compiling atapio.g... " 1 platform_log ;
  "atapio.g" platform_g_compile ;
  "done!\n" 1 platform_log ;

  "Compiling diskfs.g... " 1 platform_log ;
  "diskfs.g" platform_g_compile ;
  "done!\n" 1 platform_log ;

  "Compiling debugfs.g... " 1 platform_log ;
  "debugfs.g" platform_g_compile ;
  "done!\n" 1 platform_log ;

  "Compiling ramfs.g... " 1 platform_log ;
  "ramfs.g" platform_g_compile ;
  "done!\n" 1 platform_log ;

  "Compiling mbr.g... " 1 platform_log ;
  "mbr.g" platform_g_compile ;
  "done!\n" 1 platform_log ;

  "Compiling vfs.g... " 1 platform_log ;
  "vfs.g" platform_g_compile ;
  "done!\n" 1 platform_log ;

  "Compiling vfs_utils.g... " 1 platform_log ;
  "vfs_utils.g" platform_g_compile ;
  "done!\n" 1 platform_log ;

  if RUN_ASM RUN_FASM || {
    #"Memory break before ASM assembler compilation: " 1 platform_log ;
    #0 platform_allocate itoa 1 platform_log ;
    #"\n" 1 platform_log ;

    "Compiling asm_regs.g... " 1 platform_log ;
    "asm_regs.g" platform_g_compile ;
    "done!\n" 1 platform_log ;

    "Compiling asm_preproc.g... " 1 platform_log ;
    "asm_preproc.g" platform_g_compile ;
    "done!\n" 1 platform_log ;

    "Compiling asm_opcodes.g... " 1 platform_log ;
    "asm_opcodes.g" platform_g_compile ;
    "done!\n" 1 platform_log ;

    "Compiling asm_compile.g... " 1 platform_log ;
    "asm_compile.g" platform_g_compile ;
    "done!\n" 1 platform_log ;

    #"Memory break after ASM assembler compilation: " 1 platform_log ;
    #0 platform_allocate itoa 1 platform_log ;
    #"\n" 1 platform_log ;
  }

  if RUN_C RUN_MCPP || RUN_TINYCC || TEST_C || {
    "Compiling c_ast.g... " 1 platform_log ;
    "c_ast.g" platform_g_compile ;
    "done!\n" 1 platform_log ;

    "Compiling c_preproc.g... " 1 platform_log ;
    "c_preproc.g" platform_g_compile ;
    "done!\n" 1 platform_log ;

    "Compiling c_compile.g... " 1 platform_log ;
    "c_compile.g" platform_g_compile ;
    "done!\n" 1 platform_log ;

    "Compiling c_test.g... " 1 platform_log ;
    "c_test.g" platform_g_compile ;
    "done!\n" 1 platform_log ;
  }

  if RUN_MESCC {
    "Compiling mescc_hex2.g... " 1 platform_log ;
    "mescc_hex2.g" platform_g_compile ;
    "done!\n" 1 platform_log ;

    "Compiling mescc_m1.g... " 1 platform_log ;
    "mescc_m1.g" platform_g_compile ;
    "done!\n" 1 platform_log ;

    "Compiling mescc_m2.g... " 1 platform_log ;
    "mescc_m2.g" platform_g_compile ;
    "done!\n" 1 platform_log ;
  }

  "Memory break after compilers compilation: " 1 platform_log ;
  0 platform_allocate itoa 1 platform_log ;
  "\n" 1 platform_log ;

  "Initializing Virtual File System...\n" 1 platform_log ;
  0 "vfs_init" platform_get_symbol \0 ;
  "Virtual File System initialized!\n" 1 platform_log ;

  # Determine if there is an actual script
  $script_file
  @script_file "/init/script.g" 0 "vfs_open" platform_get_symbol \1 = ;
  $have_script
  @have_script script_file 0 "vfs_read" platform_get_symbol \1 0xffffffff != = ;
  script_file 0 "vfs_close" platform_get_symbol \1 ;

  if have_script {
    "Compiling script.g... " 1 platform_log ;
    "script.g" platform_g_compile ;
    "done!\n" 1 platform_log ;

    "Running the script...\n" 1 platform_log ;
    0 "run_script" platform_get_symbol \0 ;
  } else {
    "No script, running the usual payload...\n" 1 platform_log ;
    if RUN_ASM {
      "/init/test.asm" 0 "parse_asm" platform_get_symbol \1 ;
    }

    if RUN_FASM {
      "Compiling fasm.g... " 1 platform_log ;
      "fasm.g" platform_g_compile ;
      "done!\n" 1 platform_log ;

      0 "compile_fasm" platform_get_symbol \0 ;
    }

    if RUN_C {
      "/disk1/tests/test.c" 0 "parse_c" platform_get_symbol \1 ;
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
      "Compiling mcpp.g... " 1 platform_log ;
      "mcpp.g" platform_g_compile ;
      "done!\n" 1 platform_log ;

      0 "compile_mcpp" platform_get_symbol \0 ;
    }

    if RUN_TINYCC {
      "Compiling tinycc.g... " 1 platform_log ;
      "tinycc.g" platform_g_compile ;
      "done!\n" 1 platform_log ;

      0 "compile_tinycc" platform_get_symbol \0 ;
    }
  }

  "Destroying Virtual File System... " 1 platform_log ;
  0 "vfs_destroy" platform_get_symbol \0 ;
  "done!\n" 1 platform_log ;

  "Destroying debugfs... " 1 platform_log ;
  0 "debugfs_deinit" platform_get_symbol \0 ;
  "done!\n" 1 platform_log ;

  "Memory break before exiting main: " 1 platform_log ;
  0 platform_allocate itoa 1 platform_log ;
  "\n" 1 platform_log ;

  0 "malloc_stats" platform_get_symbol \0 ;
}
