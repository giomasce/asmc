
#include "stdint.h"
#include "ctype.h"
#include "string.h"
#include "errno.h"
#include "limits.h"
#include "_digits.h"

// All code in this file was taken from PDClib

intmax_t _atomax( const char * s )
{
    intmax_t rc = 0;
    char sign = '+';
    const char * x;
    /* TODO: In other than "C" locale, additional patterns may be defined     */
    while ( isspace( *s ) ) ++s;
    if ( *s == '+' ) ++s;
    else if ( *s == '-' ) sign = *(s++);
    /* TODO: Earlier version was missing tolower() but was not caught by tests */
    while ( ( x = memchr( _digits, tolower(*(s++)), 10 ) ) != NULL )
    {
        rc = rc * 10 + ( x - _digits );
    }
    return ( sign == '+' ) ? rc : -rc;
}

int atoi( const char * s )
{
    return (int) _atomax( s );
}

const char * _strtox_prelim( const char * p, char * sign, int * base )
{
    /* skipping leading whitespace */
    while ( isspace( *p ) ) ++p;
    /* determining / skipping sign */
    if ( *p != '+' && *p != '-' ) *sign = '+';
    else *sign = *(p++);
    /* determining base */
    if ( *p == '0' )
    {
        ++p;
        if ( ( *base == 0 || *base == 16 ) && ( *p == 'x' || *p == 'X' ) )
        {
            *base = 16;
            ++p;
            /* catching a border case here: "0x" followed by a non-digit should
               be parsed as the unprefixed zero.
               We have to "rewind" the parsing; having the base set to 16 if it
               was zero previously does not hurt, as the result is zero anyway.
            */
            if ( memchr( _digits, tolower(*p), *base ) == NULL )
            {
                p -= 2;
            }
        }
        else if ( *base == 0 )
        {
            *base = 8;
            /* Rewind one character back, so that the string composed
               of just a zero is correctly parsed (and endptr is set
               appropriately). */
            --p;
        }
        else
        {
            --p;
        }
    }
    else if ( ! *base )
    {
        *base = 10;
    }
    return ( ( *base >= 2 ) && ( *base <= 36 ) ) ? p : NULL;
}

uintmax_t _strtox_main( const char ** p, unsigned int base, uintmax_t error, uintmax_t limval, int limdigit, char * sign )
{
    uintmax_t rc = 0;
    int digit = -1;
    const char * x;
    while ( ( x = memchr( _digits, tolower(**p), base ) ) != NULL )
    {
        digit = x - _digits;
        if ( ( rc < limval ) || ( ( rc == limval ) && ( digit <= limdigit ) ) )
        {
            rc = rc * base + (unsigned)digit;
            ++(*p);
        }
        else
        {
            errno = ERANGE;
            /* TODO: Only if endptr != NULL - but do we really want *another* parameter? */
            /* TODO: Earlier version was missing tolower() here but was not caught by tests */
            while ( memchr( _digits, tolower(**p), base ) != NULL ) ++(*p);
            /* TODO: This is ugly, but keeps caller from negating the error value */
            *sign = '+';
            return error;
        }
    }
    if ( digit == -1 )
    {
        *p = NULL;
        return 0;
    }
    return rc;
}

long int strtol( const char * s, char ** endptr, int base )
{
    long int rc;
    char sign = '+';
    const char * p = _strtox_prelim( s, &sign, &base );
    if ( base < 2 || base > 36 ) return 0;
    if ( sign == '+' )
    {
        rc = (long int)_strtox_main( &p, (unsigned)base, (uintmax_t)LONG_MAX, (uintmax_t)( LONG_MAX / base ), (int)( LONG_MAX % base ), &sign );
    }
    else
    {
        rc = (long int)_strtox_main( &p, (unsigned)base, (uintmax_t)LONG_MIN, (uintmax_t)( LONG_MIN / -base ), (int)( -( LONG_MIN % base ) ), &sign );
    }
    if ( endptr != NULL ) *endptr = ( p != NULL ) ? (char *) p : (char *) s;
    return ( sign == '+' ) ? rc : -rc;
}

long long int strtoll( const char * s, char ** endptr, int base )
{
    long long int rc;
    char sign = '+';
    const char * p = _strtox_prelim( s, &sign, &base );
    if ( base < 2 || base > 36 ) return 0;
    if ( sign == '+' )
    {
        rc = (long long int)_strtox_main( &p, (unsigned)base, (uintmax_t)LLONG_MAX, (uintmax_t)( LLONG_MAX / base ), (int)( LLONG_MAX % base ), &sign );
    }
    else
    {
        rc = (long long int)_strtox_main( &p, (unsigned)base, (uintmax_t)LLONG_MIN, (uintmax_t)( LLONG_MIN / -base ), (int)( -( LLONG_MIN % base ) ), &sign );
    }
    if ( endptr != NULL ) *endptr = ( p != NULL ) ? (char *) p : (char *) s;
    return ( sign == '+' ) ? rc : -rc;
}

unsigned long int strtoul( const char * s, char ** endptr, int base )
{
    unsigned long int rc;
    char sign = '+';
    const char * p = _strtox_prelim( s, &sign, &base );
    if ( base < 2 || base > 36 ) return 0;
    rc = (unsigned long int)_strtox_main( &p, (unsigned)base, (uintmax_t)ULONG_MAX, (uintmax_t)( ULONG_MAX / base ), (int)( ULONG_MAX % base ), &sign );
    if ( endptr != NULL ) *endptr = ( p != NULL ) ? (char *) p : (char *) s;
    return ( sign == '+' ) ? rc : -rc;
}

unsigned long long int strtoull( const char * s, char ** endptr, int base )
{
    unsigned long long int rc;
    char sign = '+';
    const char * p = _strtox_prelim( s, &sign, &base );
    if ( base < 2 || base > 36 ) return 0;
    rc = _strtox_main( &p, (unsigned)base, (uintmax_t)ULLONG_MAX, (uintmax_t)( ULLONG_MAX / base ), (int)( ULLONG_MAX % base ), &sign );
    if ( endptr != NULL ) *endptr = ( p != NULL ) ? (char *) p : (char *) s;
    return ( sign == '+' ) ? rc : -rc;
}
