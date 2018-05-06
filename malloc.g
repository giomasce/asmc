
# Malloc
# Based on https://github.com/andrestc/linux-prog/blob/master/ch7/malloc.c
$head

const SIZE_OF_BLOCK 12
const ALLOC_UNIT 12288

fun take_size 1 {
  0 param ** ret ;
}

fun take_size_addr 1 {
  0 param ret ;
}

fun take_next 1 {
  0 param 4 + ** ret ;
}

fun take_next_addr 1 {
  0 param 4 + ret ;
}

fun take_prev 1 {
  0 param 8 + ** ret ;
}

fun take_prev_addr 1 {
  0 param 8 + ret ;
}

fun fl_remove 1 {
  $b
  @b 0 param = ;
  if b take_prev ! {
    if b take_next {
      @head b take_next = ;
    } else {
      @head 0 = ;
    }
  } else {
    b take_prev take_next_addr b take_next = ;
  }
  if b take_next {
    b take_next take_prev_addr b take_prev = ;
  }
}

fun fl_add 1 {
  $b
  @b 0 param = ;
  b take_next_addr 0 = ;
  b take_prev_addr 0 = ;
  if head ! head b > || {
    if head {
      head take_prev_addr b = ;
    }
    b take_next_addr head = ;
    @head b = ;
  } else {
    $curr
    @curr head = ;
    $cond
    @cond curr take_next = ;
    if cond {
      @cond curr take_next b < = ;
    }
    while cond {
      @curr curr take_next = ;
      @cond curr take_next = ;
      if cond {
        @cond curr take_next b < = ;
      }
    }
    b take_next_addr curr take_next = ;
    curr take_next_addr b = ;
  }
}

fun scan_merge 0 {
  $curr
  @curr head = ;
  $header_curr
  $header_next
  $break
  @break 0 = ;
  while curr take_next break ! && {
    @header_curr curr = ;
    @header_next curr take_next = ;
    if header_curr curr take_size + SIZE_OF_BLOCK + header_next == {
      curr take_size_addr curr take_size curr take_next take_size + SIZE_OF_BLOCK + = ;
      curr take_next_addr curr take_next take_next = ;
      if curr take_next {
        curr take_next take_prev_addr curr = ;
      } else {
        @break 1 = ;
      }
    }
    @curr curr take_next = ;
  }
}

fun split 2 {
  $b
  $size
  @b 0 param = ;
  @size 1 param = ;
  $mem_block
  @mem_block b SIZE_OF_BLOCK + = ;
  $newptr
  @newptr mem_block size + = ;
  newptr take_size_addr b take_size size - SIZE_OF_BLOCK - = ;
  b take_size_addr size = ;
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
    @alloc_size size SIZE_OF_BLOCK + = ;
  } else {
    @alloc_size ALLOC_UNIT = ;
  }
  @ptr head = ;
  while ptr {
    if ptr take_size size SIZE_OF_BLOCK + >= {
      @block_mem ptr SIZE_OF_BLOCK + = ;
      ptr fl_remove ;
      @newptr size ptr split = ;
      newptr fl_add ;
      block_mem ret ;
    } else {
      @ptr ptr take_next = ;
    }
  }
  @ptr alloc_size platform_allocate = ;
  ptr take_next_addr 0 = ;
  ptr take_prev_addr 0 = ;
  ptr take_size_addr alloc_size SIZE_OF_BLOCK - = ;
  if alloc_size size SIZE_OF_BLOCK + > {
    @newptr size ptr split = ;
    newptr fl_add ;
  }
  ptr SIZE_OF_BLOCK + ret ;
}

fun free 1 {
  $ptr
  @ptr 0 param = ;
  ptr SIZE_OF_BLOCK - fl_add ;
  scan_merge ;
}

fun realloc 2 {
  $ptr
  $newsize
  @ptr 0 param = ;
  @newsize 1 param = ;
  $size
  @size ptr SIZE_OF_BLOCK - take_size = ;
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
