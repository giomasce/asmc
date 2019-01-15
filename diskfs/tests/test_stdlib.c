/* This file is part of asmc, a bootstrapping OS with minimal seed
   Copyright (C) 2018 Giovanni Mascellani <gio@debian.org>
   https://gitlab.com/giomasce/asmc

   This program is free software: you can redistribute it and/or modify
   it under the terms of the GNU General Public License as published by
   the Free Software Foundation, either version 3 of the License, or
   (at your option) any later version.

   This program is distributed in the hope that it will be useful,
   but WITHOUT ANY WARRANTY; without even the implied warranty of
   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
   GNU General Public License for more details.

   You should have received a copy of the GNU General Public License
   along with this program.  If not, see <https://www.gnu.org/licenses/>. */

#include <stdlib.h>

int test_malloc_free() {
  void *ptr;
  ptr = malloc(10);
  free(ptr);
  return ptr != NULL;
}

int test_calloc_free() {
  void *ptr;
  ptr = calloc(50, 20);
  free(ptr);
  return ptr != NULL;
}

int test_malloc_realloc_free() {
  char *ptr;
  ptr = malloc(100);
  *ptr = 'A';
  *(ptr+1) = 'B';
  *(ptr+49) = 'Z';
  ptr = realloc(ptr, 50);
  if (*ptr != 'A') return 0;
  if (*(ptr+1) != 'B') return 0;
  if (*(ptr+49) != 'Z') return 0;
  ptr = realloc(ptr, 200);
  if (*ptr != 'A') return 0;
  if (*(ptr+1) != 'B') return 0;
  if (*(ptr+49) != 'Z') return 0;
  free(ptr);
  return ptr != NULL;
}

int test_free_null() {
  free(NULL);
  free(0);
  return 1;
}

int test_realloc_null_free() {
    char *ptr = realloc(NULL, 100);
    free(ptr);
    return ptr != NULL;
}

static int compare( const void * left, const void * right )
{
    return *( (unsigned char *)left ) - *( (unsigned char *)right );
}

char presort[] = "shreicnyjqpvozxmbt";
char sorted1[] = "bcehijmnopqrstvxyz";
char sorted2[] = "bticjqnyozpvreshxm";

// From PDClib
int test_qsort() {
    char s[19];
    strcpy( s, presort );
    qsort( s, 18, 1, compare );
    if ( strcmp( s, sorted1 ) != 0 ) return 0;
    strcpy( s, presort );
    qsort( s, 9, 2, compare );
    if ( strcmp( s, sorted2 ) != 0 ) return 0;
    strcpy( s, presort );
    qsort( s, 1, 1, compare );
    if ( strcmp( s, presort ) != 0 ) return 0;
    qsort( s, 100, 0, compare );
    if ( strcmp( s, presort ) != 0 ) return 0;
    return 1;
}

int test_strtoull_zero() {
    char *p = "0";
    char *q;
    unsigned long long n = strtoull(p, &q, 0);
    if (*q != '\0') return 0;
    if (n != 0) return 0;
    return 1;
}
