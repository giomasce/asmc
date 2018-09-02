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

fun c_run_testcase 3 {
  $tests
  $filename
  $function
  $result
  @tests 3 param = ;
  @filename 2 param = ;
  @function 1 param = ;
  @result 0 param = ;

  "Testing " 1 platform_log ;
  function 1 platform_log ;
  " in file " 1 platform_log ;
  filename 1 platform_log ;
  "..." 1 platform_log ;

  # Preprocessing
  $ctx
  @ctx ppctx_init = ;
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

  # Debug output
  #"TYPES TABLE\n" 1 platform_log ;
  #cctx cctx_dump_types ;
  #"TYPE NAMES TABLE\n" 1 platform_log ;
  #cctx cctx_dump_typenames ;
  #"GLOBALS TABLE\n" 1 platform_log ;
  #cctx cctx_dump_globals ;

  # Try to execute the code
  #"Executing compiled code...\n" 1 platform_log ;
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
  if res result == {
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

  tests "/disk1/tests/test_lang.c" "test_false" 0 c_run_testcase ;
  tests "/disk1/tests/test_lang.c" "test_true" 1 c_run_testcase ;
  tests "/disk1/tests/test_lang.c" "test_while" 5040 c_run_testcase ;
  tests "/disk1/tests/test_lang.c" "test_for" 5040 c_run_testcase ;
  tests "/disk1/tests/test_lang.c" "test_array" 200 c_run_testcase ;
  tests "/disk1/tests/test_lang.c" "test_struct" 40 c_run_testcase ;
  tests "/disk1/tests/test_lang.c" "test_enum" 11 c_run_testcase ;
  tests "/disk1/tests/test_lang.c" "test_strings" 1 c_run_testcase ;
  tests "/disk1/tests/test_lang.c" "test_define" 4 c_run_testcase ;
  tests "/disk1/tests/test_lang.c" "test_extension" 0xffffffff c_run_testcase ;

  tests TESTS_SUCCESSFUL take itoa 1 platform_log ;
  " / " 1 platform_log ;
  tests TESTS_RAN take itoa 1 platform_log ;
  " tests succesfully passed\n" 1 platform_log ;

  tests free ;
}
