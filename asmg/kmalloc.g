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

# This memory allocator is based on the same ideas as kmalloc.c (see
# for example [1]), but the implementation is completely new and some
# bits were simplified (for example, page size is ignored, because
# there is not virtual memory around). It is rewritten from scratch
# anyway.
#
# [1] https://github.com/emeryberger/Malloc-Implementations/blob/master/allocators/kmalloc/kmalloc.c

const KMALLOC_NBUCKETS 28

$kmalloc_buckets
$kmalloc_num

fun _bucket_actual_size 1 {
  $bucket
  @bucket 0 param = ;

  0 bucket <= bucket KMALLOC_NBUCKETS < && "_bucket_actual_size: invalid bucket number" assert_msg ;

  $actual
  @actual 1 bucket 3 + << = ;
  actual ret ;
}

fun malloc 1 {
  $size
  @size 0 param = ;

  if size 0 == {
    0 ret ;
  }
  size 0 > "malloc: invalid negative size" assert_msg ;

  @kmalloc_num kmalloc_num 1 + = ;

  # Initialize buckets on first call
  if kmalloc_buckets 0 == {
    @kmalloc_buckets KMALLOC_NBUCKETS 4 * platform_allocate = ;
    $i
    @i 0 = ;
    while i KMALLOC_NBUCKETS < {
      kmalloc_buckets 4 i * + 0 = ;
      @i i 1 + = ;
    }
  }

  # Find the appropriate bucket size
  $actual
  $bucket
  @bucket 0 = ;
  $cont
  @cont 1 = ;
  while cont {
    @actual bucket _bucket_actual_size = ;
    if size 4 + actual <= {
      @cont 0 = ;
    } else {
      @bucket bucket 1 + = ;
    }
  }

  # Take a region from the appropriate bucket, or request a new one
  $ptr
  @ptr kmalloc_buckets 4 bucket * + ** = ;
  if ptr 0 == {
    @ptr actual platform_allocate = ;
  } else {
    kmalloc_buckets 4 bucket * + ptr ** = ;
  }

  ptr bucket = ;
  ptr 4 + ret ;
}

fun free 1 {
  $buf
  @buf 0 param = ;

  if buf 0 == {
    ret ;
  }

  kmalloc_num 0 > "free: mismatched free" assert_msg ;
  @kmalloc_num kmalloc_num 1 - = ;

  $ptr
  @ptr buf 4 - = ;

  $bucket
  @bucket ptr ** = ;
  # Just for checking that the bucket number is valid
  bucket _bucket_actual_size ;

  ptr kmalloc_buckets 4 bucket * + ** = ;
  kmalloc_buckets 4 bucket * + ptr = ;
}

fun _malloc_get_size 1 {
  $buf
  @buf 0 param = ;

  $ptr
  @ptr buf 4 - = ;

  $bucket
  @bucket ptr ** = ;

  $actual
  @actual bucket _bucket_actual_size = ;
  $size
  @size actual 4 - = ;
  size ret ;
}

fun malloc_stats 0 {
  kmalloc_num itoa 1 platform_log ;
  " malloc-ed regions were never free-d\n" 1 platform_log ;
}
