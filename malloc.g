
# Malloc
# Based on https://github.com/andrestc/linux-prog/blob/master/ch7/malloc.c
# A few bugs were fixed

$head

const MALLOC_MAGIC_ALLOC 0xfeedbeef
const MALLOC_MAGIC_FREE 0xdeadc0de

const MALLOC_SIZE 0
const MALLOC_NEXT 4
const MALLOC_PREV 8
const MALLOC_MAGIC 12
const SIZEOF_MALLOC 16

const ALLOC_UNIT 16384

fun fl_remove 1 {
  $b
  @b 0 param = ;
  if b MALLOC_PREV take ! {
    if b MALLOC_NEXT take {
      @head b MALLOC_NEXT take = ;
    } else {
      @head 0 = ;
    }
  } else {
    b MALLOC_PREV take MALLOC_NEXT take_addr b MALLOC_NEXT take = ;
  }
  if b MALLOC_NEXT take {
    b MALLOC_NEXT take MALLOC_PREV take_addr b MALLOC_PREV take = ;
  }
}

fun fl_add 1 {
  $b
  @b 0 param = ;
  b MALLOC_MAGIC take MALLOC_MAGIC_FREE == "fl_add: missing magic number" assert_msg ;
  b MALLOC_NEXT take_addr 0 = ;
  b MALLOC_PREV take_addr 0 = ;
  if head ! head b > || {
    if head {
      head MALLOC_PREV take_addr b = ;
    }
    b MALLOC_NEXT take_addr head = ;
    @head b = ;
  } else {
    $curr
    @curr head = ;
    while curr MALLOC_NEXT take curr MALLOC_NEXT take b < && {
      @curr curr MALLOC_NEXT take = ;
    }
    $next
    @next curr MALLOC_NEXT take = ;
    b MALLOC_NEXT take_addr next = ;
    b MALLOC_PREV take_addr curr = ;
    curr MALLOC_NEXT take_addr b = ;
    next MALLOC_PREV take_addr b = ;
  }
}

fun scan_merge 0 {
  $curr
  @curr head = ;
  while curr MALLOC_NEXT take {
    $next
    @next curr MALLOC_NEXT take = ;
    if curr curr MALLOC_SIZE take + SIZEOF_MALLOC + next == {
      curr MALLOC_SIZE take_addr curr MALLOC_SIZE take next MALLOC_SIZE take + SIZEOF_MALLOC + = ;
      curr MALLOC_NEXT take_addr next MALLOC_NEXT take = ;
      if curr MALLOC_NEXT take {
        curr MALLOC_NEXT take MALLOC_PREV take_addr curr = ;
      }
    } else {
      @curr curr MALLOC_NEXT take = ;
    }
  }
}

fun split 2 {
  $b
  $size
  @b 0 param = ;
  @size 1 param = ;
  $mem_block
  @mem_block b SIZEOF_MALLOC + = ;
  $newptr
  @newptr mem_block size + = ;
  newptr MALLOC_SIZE take_addr b MALLOC_SIZE take size - SIZEOF_MALLOC - = ;
  newptr MALLOC_MAGIC take_addr MALLOC_MAGIC_FREE = ;
  b MALLOC_SIZE take_addr size = ;
  newptr ret ;
}

fun check_fl 0 {
  $ptr
  $prevptr
  @ptr head = ;
  @prevptr 0 = ;
  while ptr {
    ptr MALLOC_MAGIC take MALLOC_MAGIC_FREE == "check_fl: wrong magic number" assert_msg ;
    ptr MALLOC_SIZE take 0xf & 0 == "check_fl: wrong alignment" assert_msg ;
    ptr MALLOC_PREV take prevptr == "check_fl: wrong prev" assert_msg ;
    ptr MALLOC_NEXT take 0 == ptr MALLOC_NEXT take ptr > || "check_fl: regions are not increasing" assert_msg ;
    ptr MALLOC_NEXT take 0 == ptr MALLOC_NEXT take ptr ptr MALLOC_SIZE take + SIZEOF_MALLOC + >= || "check_fl: adjacent regions are overlapping" assert_msg ;
    ptr MALLOC_NEXT take 0 == ptr MALLOC_NEXT take ptr ptr MALLOC_SIZE take + SIZEOF_MALLOC + > || "check_fl: adjacent regions are contiguous" assert_msg ;
    @prevptr ptr = ;
    @ptr ptr MALLOC_NEXT take = ;
  }
}

fun malloc 1 {
  $size
  @size 0 param = ;
  # Make it a multiple of 16
  @size size 1 - 0xf | 1 + = ;
  $block_mem
  $ptr
  $newptr
  $alloc_size
  if size SIZEOF_MALLOC 2 * + ALLOC_UNIT <= {
    @alloc_size ALLOC_UNIT = ;
  } else {
    @alloc_size size SIZEOF_MALLOC + = ;
  }
  @ptr head = ;
  while ptr {
    ptr MALLOC_MAGIC take MALLOC_MAGIC_FREE == "malloc: missing magic number" assert_msg ;
    ptr MALLOC_SIZE take 0xf & 0 == "malloc: error 3" assert_msg ;
    if ptr MALLOC_SIZE take size SIZEOF_MALLOC + >= {
      @block_mem ptr SIZEOF_MALLOC + = ;
      ptr fl_remove ;
      @newptr size ptr split = ;
      newptr fl_add ;
      ptr MALLOC_MAGIC take_addr MALLOC_MAGIC_ALLOC = ;
      block_mem 0xf & 0 == "malloc: error 1" assert_msg ;
      block_mem ret ;
    } else {
      @ptr ptr MALLOC_NEXT take = ;
    }
  }
  @ptr alloc_size platform_allocate = ;
  ptr MALLOC_NEXT take_addr 0 = ;
  ptr MALLOC_PREV take_addr 0 = ;
  ptr MALLOC_SIZE take_addr alloc_size SIZEOF_MALLOC - = ;
  ptr MALLOC_MAGIC take_addr MALLOC_MAGIC_ALLOC = ;
  if alloc_size size SIZEOF_MALLOC + > {
    @newptr size ptr split = ;
    newptr fl_add ;
  }
  @block_mem ptr SIZEOF_MALLOC + = ;
  block_mem 0xf & 0 == "malloc: error 2" assert_msg ;
  block_mem ret ;
}

fun free 1 {
  $ptr
  @ptr 0 param = ;
  if ptr 0 == {
    ret ;
  }
  $b
  @b ptr SIZEOF_MALLOC - = ;
  b MALLOC_MAGIC take MALLOC_MAGIC_ALLOC == "free: missing magic number" assert_msg ;
  b MALLOC_MAGIC take_addr MALLOC_MAGIC_FREE = ;
  b fl_add ;
  scan_merge ;
  # For debugging, it can be helpful to check the state
  # of the free list after each call of free
  #check_fl ;
}

fun realloc 2 {
  $ptr
  $newsize
  @ptr 0 param = ;
  @newsize 1 param = ;
  $size
  @size ptr SIZEOF_MALLOC - MALLOC_SIZE take = ;
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
