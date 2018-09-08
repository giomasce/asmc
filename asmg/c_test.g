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

const TESTS_RAN 0
const TESTS_SUCCESSFUL 4
const SIZEOF_TESTS 8

$test_expected_stdout
$test_stdout_ok

fun test_platform_write_char 2 {
  $c
  $fd
  @c 1 param = ;
  @fd 0 param = ;

  if test_expected_stdout **c c == {
    @test_expected_stdout test_expected_stdout 1 + = ;
  } else {
    @test_stdout_ok 0 = ;
  }
}

fun c_run_testcase 3 {
  $tests
  $filename
  $function
  $result
  $out
  @tests 4 param = ;
  @filename 3 param = ;
  @function 2 param = ;
  @result 1 param = ;
  @out 0 param = ;

  "Testing " 1 platform_log ;
  function 1 platform_log ;
  " in file " 1 platform_log ;
  filename 1 platform_log ;
  "..." 1 platform_log ;

  # Preprocessing
  $ctx
  @ctx ppctx_init = ;
  ctx PPCTX_VERBOSE take_addr 0 = ;
  ctx filename ppctx_set_base_filename ;
  $tokens
  @tokens 4 vector_init = ;
  tokens ctx filename preproc_file ;
  @tokens tokens remove_whites = ;
  #"Finished preprocessing\n" 1 platform_log ;
  #tokens print_token_list ;

  # Compilation
  $cctx
  @cctx tokens cctx_init = ;
  cctx CCTX_VERBOSE take_addr 0 = ;
  cctx cctx_compile ;

  # Hack the handles in order to intercept calls to platform_write_char
  cctx CCTX_HANDLES take 0 vector_at_addr @test_platform_write_char = ;
  @test_expected_stdout out = ;
  @test_stdout_ok 1 = ;

  # Debug output
  #"TYPES TABLE\n" 1 platform_log ;
  #cctx cctx_dump_types ;
  #"TYPE NAMES TABLE\n" 1 platform_log ;
  #cctx cctx_dump_typenames ;
  #"GLOBALS TABLE\n" 1 platform_log ;
  #cctx cctx_dump_globals ;

  # Try to execute the code
  #"Executing compiled code...\n" 1 platform_log ;
  if cctx "__init_stdlib" cctx_has_global {
    $init_global
    @init_global cctx "__init_stdlib" cctx_get_global = ;
    $init_addr
    @init_addr init_global GLOBAL_LOC take = ;
    init_addr \0 ;
  }
  $function_global
  @function_global cctx function cctx_get_global = ;
  $function_addr
  @function_addr function_global GLOBAL_LOC take = ;
  $res
  @res function_addr \0 = ;
  #"It returned " 1 platform_log ;
  #res itoa 1 platform_log ;
  #"\n" 1 platform_log ;

  # Cleanup
  tokens free_vect_of_ptrs ;
  cctx cctx_destroy ;
  ctx ppctx_destroy ;

  tests TESTS_RAN take_addr tests TESTS_RAN take 1 + = ;
  if res result == test_expected_stdout **c 0 == && test_stdout_ok && {
    " passed!\n" 1 platform_log ;
    tests TESTS_SUCCESSFUL take_addr tests TESTS_SUCCESSFUL take 1 + = ;
  } else {
    " FAILED!\n" 1 platform_log ;
  }
}

fun c_run_testcases 0 {
  $tests
  @tests SIZEOF_TESTS malloc = ;
  tests TESTS_RAN take_addr 0 = ;
  tests TESTS_SUCCESSFUL take_addr 0 = ;

  tests "/disk1/tests/test_lang.c" "test_false" 0 "" c_run_testcase ;
  tests "/disk1/tests/test_lang.c" "test_true" 1 "" c_run_testcase ;
  tests "/disk1/tests/test_lang.c" "test_while" 5040 "" c_run_testcase ;
  tests "/disk1/tests/test_lang.c" "test_for" 5040 "" c_run_testcase ;
  tests "/disk1/tests/test_lang.c" "test_array" 200 "" c_run_testcase ;
  tests "/disk1/tests/test_lang.c" "test_struct" 40 "" c_run_testcase ;
  tests "/disk1/tests/test_lang.c" "test_enum" 11 "" c_run_testcase ;
  tests "/disk1/tests/test_lang.c" "test_strings" 1 "" c_run_testcase ;
  tests "/disk1/tests/test_lang.c" "test_define" 4 "" c_run_testcase ;
  tests "/disk1/tests/test_lang.c" "test_extension" 0xffffffff "" c_run_testcase ;

  tests "/disk1/tests/test_stdio.c" "test_fputs" 1 "This is a test string\n" c_run_testcase ;
  tests "/disk1/tests/test_stdio.c" "test_puts" 1 "This is a test string\n" c_run_testcase ;
  tests "/disk1/tests/test_stdio.c" "test_putchar" 1 "X" c_run_testcase ;
  tests "/disk1/tests/test_stdio.c" "test_fputc" 1 "X" c_run_testcase ;
  tests "/disk1/tests/test_stdio.c" "test_putc" 1 "X" c_run_testcase ;

  tests "/disk1/tests/test_stdlib.c" "test_malloc_free" 1 "" c_run_testcase ;
  tests "/disk1/tests/test_stdlib.c" "test_calloc_free" 1 "" c_run_testcase ;
  tests "/disk1/tests/test_stdlib.c" "test_malloc_realloc_free" 1 "" c_run_testcase ;
  tests "/disk1/tests/test_stdlib.c" "test_free_null" 1 "" c_run_testcase ;

  tests "/disk1/tests/test_string.c" "test_strcmp1" 1 "" c_run_testcase ;
  tests "/disk1/tests/test_string.c" "test_strcmp2" 1 "" c_run_testcase ;
  tests "/disk1/tests/test_string.c" "test_strcmp3" 1 "" c_run_testcase ;
  tests "/disk1/tests/test_string.c" "test_strcmp4" 1 "" c_run_testcase ;

  tests TESTS_SUCCESSFUL take itoa 1 platform_log ;
  " / " 1 platform_log ;
  tests TESTS_RAN take itoa 1 platform_log ;
  " tests succesfully passed\n" 1 platform_log ;

  tests free ;
}
