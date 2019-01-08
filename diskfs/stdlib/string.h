#ifndef __STRING_H
#define __STRING_H

#include "asmc_types.h"

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

// From PDClib
char * strcpy( char * s1, const char * s2 )
{
    char * rc = s1;
    while ( ( *s1++ = *s2++ ) );
    return rc;
}

// From PDClib
char * strchr( const char * s, int c )
{
    do
    {
        if ( *s == (char) c )
        {
            return (char *) s;
        }
    } while ( *s++ );
    return NULL;
}

// From PDClib
int strncmp( const char * s1, const char * s2, size_t n )
{
    while ( n && *s1 && ( *s1 == *s2 ) )
    {
        ++s1;
        ++s2;
        --n;
    }
    if ( n == 0 )
    {
        return 0;
    }
    else
    {
        return ( *(unsigned char *)s1 - *(unsigned char *)s2 );
    }
}

// From PDClib
char * strrchr( const char * s, int c )
{
    size_t i = 0;
    while ( s[i++] );
    do
    {
        if ( s[--i] == (char) c )
        {
            return (char *) s + i;
        }
    } while ( i );
    return NULL;
}

// From PDClib
void * memchr( const void * s, int c, size_t n )
{
    const unsigned char * p = (const unsigned char *) s;
    while ( n-- )
    {
        if ( *p == (unsigned char) c )
        {
            return (void *) p;
        }
        ++p;
    }
    return NULL;
}

// From PDClib
char * strcat( char * s1, const char * s2 )
{
    char * rc = s1;
    if ( *s1 )
    {
        while ( *++s1 );
    }
    while ( (*s1++ = *s2++) );
    return rc;
}

#endif
