
fun append_to_str 2 {
  $s1
  $s2
  @s1 0 param = ;
  @s2 1 param = ;
  $len1
  $len2
  @len1 s1 strlen = ;
  @len2 s2 strlen = ;
  $newlen
  @newlen len1 len2 + 1 + = ;
  $news
  @news newlen s2 realloc = ;
  s1 news len2 + strcpy ;
  news ret ;
}

fun free_vect_of_ptrs 1 {
  $vect
  @vect 0 param = ;
  $i
  @i 0 = ;
  #"Freeing vector of length " 1 platform_log ;
  #vect vector_size itoa 1 platform_log ;
  #"\n" 1 platform_log ;
  while i vect vector_size < {
    #i itoa 1 platform_log ;
    #" " 1 platform_log ;
    vect i vector_at free ;
    @i i 1 + = ;
  }
  vect vector_destroy ;
}

fun dup_vect_of_ptrs 1 {
  $vect
  @vect 0 param = ;
  $newvect
  @newvect 4 vector_init = ;
  $i
  @i 0 = ;
  while i vect vector_size < {
    newvect vect i vector_at strdup vector_push_back ;
    @i i 1 + = ;
  }
  newvect ret ;
}
