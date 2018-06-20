
fun malloc 1 {
  $size
  @size 0 param = ;
  $alloc_size
  # Add space for the length
  @alloc_size size 4 + = ;
  # Make it a multiple of 4
  @alloc_size alloc_size 1 - 0x3 | 1 + = ;
  $ptr
  @ptr alloc_size platform_allocate = ;
  ptr 1024 1024 * 100 * < "too much alloc" assert_msg ;
  ptr size = ;
  ptr 4 + ret ;
}

fun free 1 {
}

fun _malloc_get_size 1 {
  $ptr
  @ptr 0 param = ;
  $size
  @size ptr 4 - ** = ;
  size ret ;
}

fun malloc_stats 0 {
}
