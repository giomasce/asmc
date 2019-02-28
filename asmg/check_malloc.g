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

const MALLOC_MAX_NUM 100000
const MALLOC_GUARD_SIZE 32
const MALLOC_GUARD_BYTE 0xd4
const MALLOC_GARBAGE_BYTE 0x5c

$malloc_data
$malloc_num

fun _malloc_init 0 {
  if malloc_data 0 == {
    @malloc_data MALLOC_MAX_NUM 16 * platform_allocate = ;
  }
}

fun malloc 1 {
  $size
  @size 0 param = ;

  _malloc_init ;

  # Add two guards
  $alloc_size
  @alloc_size size MALLOC_GUARD_SIZE + MALLOC_GUARD_SIZE + = ;

  # Get memory from platform
  $ptr
  @ptr alloc_size platform_allocate = ;
  ptr 1024 1024 * 100 * < "check_malloc: too much alloc" assert_msg ;

  # Compute useful pointers
  $buf_begin
  $buf_end
  $ptr_end
  @buf_begin ptr MALLOC_GUARD_SIZE + = ;
  @buf_end buf_begin size + = ;
  @ptr_end buf_end MALLOC_GUARD_SIZE + = ;

  # Bookkeeping
  malloc_num MALLOC_MAX_NUM < "malloc: too many mallocations" assert_msg ;
  malloc_data malloc_num 16 * + size = ;
  malloc_data malloc_num 16 * + 4 + buf_begin = ;
  malloc_data malloc_num 16 * + 8 + 0 = ;
  malloc_data malloc_num 16 * + 12 + __frame_ptr 4 + ** = ;
  @malloc_num malloc_num 1 + = ;

  # Debug
  # "malloc: " log ;
  # ptr itoa log ;
  # " / " log ;
  # buf_begin itoa log ;
  # " / " log ;
  # buf_end itoa log ;
  # " / " log ;
  # ptr_end itoa log ;
  # "\n" log ;

  # Fill the guards with the guard byte
  ptr MALLOC_GUARD_BYTE MALLOC_GUARD_SIZE memset ;
  buf_end MALLOC_GUARD_BYTE MALLOC_GUARD_SIZE memset ;

  # Fill the allocated zone with garbage bytes, so that the program does not depend on it being nulled
  buf_begin MALLOC_GARBAGE_BYTE size memset ;

  buf_begin ret ;
}

fun _malloc_find_index 1 {
  $ptr
  @ptr 0 param = ;

  $i
  @i 0 = ;
  while i malloc_num < {
    if malloc_data i 16 * + 4 + ** ptr == {
      i ret ;
    }
    @i i 1 + = ;
  }

  "Unallocated address: " log ;
  ptr itoa log ;
  "\n" log ;
  0 "_malloc_find_index: requested memory region was not allocated" assert_msg ;
}

fun free 1 {
  $buf_begin
  @buf_begin 0 param = ;

  if buf_begin 0 == {
    ret ;
  }

  # Find the allocation index
  $i
  @i buf_begin _malloc_find_index = ;

  # Check the region is allocated and mark it as allocated
  malloc_data i 16 * + 8 + ** 0 == "free: double free" assert_msg ;
  malloc_data i 16 * + 8 + 1 = ;
  $size
  @size malloc_data i 16 * + ** = ;

  # Compute useful pointers
  $ptr
  $buf_end
  $ptr_end
  @ptr buf_begin MALLOC_GUARD_SIZE - = ;
  @buf_end buf_begin size + = ;
  @ptr_end buf_end MALLOC_GUARD_SIZE + = ;

  # Debug
  # "free: " log ;
  # ptr itoa log ;
  # " / " log ;
  # buf_begin itoa log ;
  # " / " log ;
  # buf_end itoa log ;
  # " / " log ;
  # ptr_end itoa log ;
  # "\n" log ;

  # Check the guard zones have not been touched
  ptr MALLOC_GUARD_BYTE MALLOC_GUARD_SIZE memcheck "free: leading guard zone has been touched" assert_msg ;
  buf_end MALLOC_GUARD_BYTE MALLOC_GUARD_SIZE memcheck "free: trailing guard zone has been touched" assert_msg ;

  # Fill the allocated zone with guard bytes, to protect against use-after-free
  buf_begin MALLOC_GUARD_BYTE size memset ;
}

fun _malloc_get_size 1 {
  $ptr
  @ptr 0 param = ;

  $i
  @i ptr _malloc_find_index = ;
  malloc_data i 16 * + ** ret ;
}

fun malloc_stats 0 {
  $i
  @i 0 = ;
  $non_freed
  @non_freed 0 = ;
  $total_size
  @total_size 0 = ;
  $non_freed_size
  @non_freed_size 0 = ;
  while i malloc_num < {
    $size
    $buf_begin
    $freed
    @size malloc_data i 16 * + ** = ;
    @buf_begin malloc_data i 16 * + 4 + ** = ;
    @freed malloc_data i 16 * + 8 + ** = ;

    # Compute useful pointers
    $ptr
    $buf_end
    $ptr_end
    @ptr buf_begin MALLOC_GUARD_SIZE - = ;
    @buf_end buf_begin size + = ;
    @ptr_end buf_end MALLOC_GUARD_SIZE + = ;

    freed 0 == freed 1 == || "malloc_stats: malloc data corruption" assert_msg ;

    # Count regions that were never freed
    if freed ! {
      @non_freed non_freed 1 + = ;
      @non_freed_size non_freed_size size + = ;
    }
    @total_size total_size size + = ;

    # Check that nothing was touched after free
    if freed {
      ptr MALLOC_GUARD_BYTE MALLOC_GUARD_SIZE memcheck "malloc_stats: leading guard zone has been touched after free" assert_msg ;
      buf_end MALLOC_GUARD_BYTE MALLOC_GUARD_SIZE memcheck "malloc_stats: trailing guard zone has been touched after free" assert_msg ;
      buf_begin MALLOC_GUARD_BYTE size memcheck "malloc_stats: memory region has been touched after free" assert_msg ;
    }

    @i i 1 + = ;
  }

  "The program did " log ;
  malloc_num itoa log ;
  " allocations (totalling " log ;
  total_size itoa log ;
  " bytes); " log ;
  non_freed itoa log ;
  " of them were never free-ed (totalling " log ;
  non_freed_size itoa log ;
  " bytes).\n" log ;
}
