
fun malloc 1 {
  $size
  @size 0 param = ;
  $alloc_size
  # Add space for the length
  @alloc_size size 4 + = ;
  # Make it a multiple of 16
  @alloc_size alloc_size 1 - 0xf | 1 + = ;
  $ptr
  @ptr alloc_size platform_allocate = ;
  ptr 1024 1024 * 100 * < "too much alloc" assert_msg ;
  ptr size = ;
  ptr 4 + ret ;
}

fun free 1 {
}

fun realloc 2 {
  $ptr
  $newsize
  @ptr 0 param = ;
  @newsize 1 param = ;
  $size
  @size ptr 4 - ** = ;
  $newptr
  @newptr newsize malloc = ;
  $copysize
  @copysize size newsize min = ;
  copysize ptr newptr memcpy ;
  ptr free ;
  newptr ret ;
}

fun strdup 1 {
  $s
  @s 0 param = ;
  $len
  @len s strlen = ;
  $ptr
  @ptr len 1 + malloc = ;
  s ptr strcpy ;
  ptr ret ;
}
