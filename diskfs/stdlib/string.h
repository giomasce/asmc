#ifndef __STRING_H
#define __STRING_H

#include "asmc.h"

int strcmp(const char *x, const char *y) {
  while (1) {
    unsigned char a = *x;
    unsigned char b = *y;
    if (a < b) return 0-1;
    if (b < a) return 1;
    if (a == 0) return 0;
    x = x + 1;
    y = y + 1;
  }
}

// From PDClib
void * memcpy( void * s1, const void * s2, size_t n )
{
    char * dest = (char *) s1;
    const char * src = (const char *) s2;
    while ( n-- )
    {
        *dest = *src;
        dest += 1;
        src += 1;
    }
    return s1;
}

// From PDClib
size_t strlen( const char * s )
{
    size_t rc = 0;
    while ( s[rc] )
    {
        ++rc;
    }
    return rc;
}

// From PDClib
void * memmove( void * s1, const void * s2, size_t n )
{
    char * dest = (char *) s1;
    const char * src = (const char *) s2;
    if ( dest <= src )
    {
        while ( n-- )
        {
            *dest = *src;
            dest += 1;
            src += 1;
        }
    }
    else
    {
        src += n;
        dest += n;
        while ( n-- )
        {
            dest -= 1;
            src -= 1;
            *dest = *src;
        }
    }
    return s1;
}

// From PDClib
void * memset( void * s, int c, size_t n )
{
    unsigned char * p = (unsigned char *) s;
    while ( n-- )
    {
        *p = (unsigned char) c;
        p += 1;
    }
    return s;
}

// From PDClib
int memcmp( const void * s1, const void * s2, size_t n )
{
    const unsigned char * p1 = (const unsigned char *) s1;
    const unsigned char * p2 = (const unsigned char *) s2;
    while ( n-- )
    {
        if ( *p1 != *p2 )
        {
            return *p1 - *p2;
        }
        p1 += 1;
        p2 += 1;
    }
    return 0;
}

#endif
