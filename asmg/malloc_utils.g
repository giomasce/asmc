
fun realloc 2 {
  $ptr
  $newsize
  @ptr 0 param = ;
  @newsize 1 param = ;
  $size
  @size ptr _malloc_get_size = ;
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
