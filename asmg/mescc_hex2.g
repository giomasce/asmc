# This file is part of asmc, a bootstrapping OS with minimal seed
# Copyright (C) 2018 Giovanni Mascellani <gio@debian.org>
# https://gitlab.com/giomasce/asmc

# This file was ported from hex2_linker.c, distributed with MES,
# which has the following copyright notices:
# Copyright (C) 2017 Jeremiah Orians
# Copyright (C) 2017 Jan Nieuwenhuizen <janneke@gnu.org>

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

fun mescc_hex2_is_white 1 {
  $c
  @c 0 param = ;
  c ' ' == c '\n' == || c '\t' == || c '\r' == || ret ;
}

fun mescc_hex2_is_alpha 1 {
  $c
  @c 0 param = ;
  if 'a' c <= c 'z' <= && { 1 ret ; }
  if 'A' c <= c 'Z' <= && { 1 ret ; }
  if '0' c <= c '9' <= && { 1 ret ; }
  0 ret ;
}

fun mescc_hex2_is_valid 1 {
  $c
  @c 0 param = ;
  if c mescc_hex2_is_alpha { 1 ret ; }
  if '!' c == '$' c == || '@' c == || '%' c == || '&' c == || ':' c == || '>' c == || { 1 ret ; }
  0 ret ;
}

fun mescc_hex2_discard_line 1 {
  $fd
  @fd 0 param = ;

  while 1 {
    $c
    @c fd vfs_read = ;
    if c '\n' == {
      ret ;
    }
  }
}

fun mescc_hex2_read 2 {
  $fd
  $accept_white
  @fd 1 param = ;
  @accept_white 0 param = ;

  while 1 {
    $c
    @c fd vfs_read = ;
    if c 0xffffffff == {
      c ret ;
    }
    if accept_white c mescc_hex2_is_white ! || {
      if c '#' == {
        fd mescc_hex2_discard_line ;
	if accept_white {
	  ' ' ret ;
	}
      } else {
        c mescc_hex2_is_valid c mescc_hex2_is_white || "mescc_hex2_read: illegal input char" assert_msg ;
	c ret ;
      }
    }
  }
}

fun mescc_hex2_read_or_fail 2 {
  $fd
  $accept_white
  @fd 1 param = ;
  @accept_white 0 param = ;

  $c
  @c fd accept_white mescc_hex2_read = ;
  c 0xffffffff != "mescc_hex2_read_or_fail: unexpected EOF" assert_msg ;
  c ret ;
}

fun mescc_hex2_read_token 2 {
  $fd
  $term_ptr
  @fd 1 param = ;
  @term_ptr 0 param = ;

  $size
  $cap
  $res
  @size 0 = ;
  @cap 10 = ;
  @res cap malloc = ;
  
  while 1 {
    if size cap == {
      @cap cap 2 * = ;
      @res res cap realloc = ;
    }
    $c
    @c fd 1 mescc_hex2_read_or_fail = ;
    if c mescc_hex2_is_white c '>' == || {
      res size + 0 =c ;
      if term_ptr {
        term_ptr c =c ;
      }
      res ret ;
    }
    c mescc_hex2_is_alpha "mescc_hex2_read_token: invalid character" assert_msg ;
    res size + c =c ;
    @size size 1 + = ;
  }
}

fun nibble_from_hex 1 {
  $c
  @c 0 param = ;

  if '0' c <= c '9' <= && {
    c '0' - ret ;
  }
  if 'a' c <= c 'f' <= && {
    c 'a' - 10 + ret ;
  }
  if 'A' c <= c 'F' <= && {
    c 'A' - 10 + ret ;
  }
  0 "nibble_from_hex: illegal input" assert_msg ;
}

fun byte_from_hex 2 {
  $c
  $c2
  @c 1 param = ;
  @c2 0 param = ;

  c nibble_from_hex 4 << c2 nibble_from_hex + ret ;
}

fun mescc_hex2_link 1 {
  $names
  @names 0 param = ;

  $orig_ptr
  $ptr
  @ptr 0 = ;
  $stage
  @stage 0 = ;
  $size
  while stage 3 < {
    "Linking stage " 1 platform_log ;
    stage 1 + itoa 1 platform_log ;
    "\n" 1 platform_log ;
    $count
    @count 0 = ;
    $name_idx
    @name_idx 0 = ;
    while name_idx names vector_size < {
      $name
      @name names name_idx vector_at = ;
      "Processing file " 1 platform_log ;
      name 1 platform_log ;
      "\n" 1 platform_log ;
      $fd
      @fd name vfs_open = ;
      $cont
      @cont 1 = ;
      while cont {
        $c
	@c fd 0 mescc_hex2_read = ;
	if c 0xffffffff == {
          @cont 0 = ;
	} else {
	  $processed
          @processed 0 = ;
          if c ':' == {
	    $label
	    $term
	    @label fd @term mescc_hex2_read_token = ;

	    label free ;
	    @processed 1 = ;
	  }
	  if c '!' == {
	    
	  }
	  if c '$' == {
	    
	  }
	  if c '@' == {
	    
	  }
	  if c '&' == {
	    
	  }
	  if c '%' == {
	    
	  }
	  if processed ! {
	    $c2
	    @c2 fd 0 mescc_hex2_read_or_fail = ;
	    if ptr 0 != {
	      ptr c c2 byte_from_hex =c ;
	      @ptr ptr 1 + = ;
	    }
	    @count count 1 + = ;
	  }
	}
      }
      fd vfs_close ;
      @name_idx name_idx 1 + = ;
    }
    if stage 0 == {
      @size count = ;
      @orig_ptr size malloc = ;
      @ptr orig_ptr = ;
    } else {
      @ptr orig_ptr = ;
      size count == "mescc_hex2_link: error 1" assert_msg ;
    }
    @stage stage 1 + = ;
  }
  "Linked program of size " 1 platform_log ;
  size itoa 1 platform_log ;
  " at address " 1 platform_log ;
  orig_ptr itoa 1 platform_log ;
  "\n" 1 platform_log ;
  "Compiled dump:\n" 1 platform_log ;
  orig_ptr size dump_mem ;
  "\n" 1 platform_log ;
  orig_ptr ret ;
}

fun mescc_hex2_test 0 {
  $files
  @files 4 vector_init = ;
  files "/init/test.hex2" strdup vector_push_back ;
  files mescc_hex2_link free ;
  files free_vect_of_ptrs ;
}
