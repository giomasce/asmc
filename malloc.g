
# Malloc
# Based on https://github.com/andrestc/linux-prog/blob/master/ch7/malloc.c
$head

const MALLOC_MAGIC_ALLOC 0xfeedbeef
const MALLOC_MAGIC_FREE 0xdeadc0de

const MALLOC_SIZE 0
const MALLOC_NEXT 4
const MALLOC_PREV 8
const MALLOC_MAGIC 12
const SIZEOF_MALLOC 16

const ALLOC_UNIT 12288

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
  b MALLOC_MAGIC take MALLOC_MAGIC_FREE == assert ;
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
    $cond
    @cond curr MALLOC_NEXT take = ;
    if cond {
      @cond curr MALLOC_NEXT take b < = ;
    }
    while cond {
      @curr curr MALLOC_NEXT take = ;
      @cond curr MALLOC_NEXT take = ;
      if cond {
        @cond curr MALLOC_NEXT take b < = ;
      }
    }
    b MALLOC_NEXT take_addr curr MALLOC_NEXT take = ;
    curr MALLOC_NEXT take_addr b = ;
  }
}

fun scan_merge 0 {
  $curr
  @curr head = ;
  $header_curr
  $header_next
  $break
  @break 0 = ;
  while curr MALLOC_NEXT take break ! && {
    @header_curr curr = ;
    @header_next curr MALLOC_NEXT take = ;
    if header_curr curr MALLOC_SIZE take + SIZEOF_MALLOC + header_next == {
      curr MALLOC_SIZE take_addr curr MALLOC_SIZE take curr MALLOC_NEXT take MALLOC_SIZE take + SIZEOF_MALLOC + = ;
      curr MALLOC_NEXT take_addr curr MALLOC_NEXT take MALLOC_NEXT take = ;
      if curr MALLOC_NEXT take {
        curr MALLOC_NEXT take MALLOC_PREV take_addr curr = ;
      } else {
        @break 1 = ;
      }
    }
    @curr curr MALLOC_NEXT take = ;
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

fun malloc 1 {
  $size
  @size 0 param = ;
  $block_mem
  $ptr
  $newptr
  $alloc_size
  if size ALLOC_UNIT >= {
    @alloc_size size SIZEOF_MALLOC + = ;
  } else {
    @alloc_size ALLOC_UNIT = ;
  }
  @ptr head = ;
  while ptr {
    if ptr MALLOC_SIZE take size SIZEOF_MALLOC + >= {
      @block_mem ptr SIZEOF_MALLOC + = ;
      ptr fl_remove ;
      @newptr size ptr split = ;
      newptr fl_add ;
      ptr MALLOC_MAGIC take MALLOC_MAGIC_FREE == assert ;
      ptr MALLOC_MAGIC take_addr MALLOC_MAGIC_ALLOC = ;
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
  ptr SIZEOF_MALLOC + ret ;
}

fun free 1 {
  $ptr
  @ptr 0 param = ;
  if ptr 0 == {
    ret ;
  }
  $b
  @b ptr SIZEOF_MALLOC - = ;
  b MALLOC_MAGIC take MALLOC_MAGIC_ALLOC == assert ;
  b MALLOC_MAGIC take_addr MALLOC_MAGIC_FREE = ;
  b fl_add ;
  scan_merge ;
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
