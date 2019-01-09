#ifndef __LIMITS_H
#define __LIMITS_H

#define CHAR_BIT 8
#define CHAR_MIN (-128)
#define CHAR_MAX 127
#define SCHAR_MIN CHAR_MIN
#define SCHAR_MAX CHAR_MAX
#define UCHAR_MAX 256

#define SHRT_MIN (-32768)
#define SHRT_MAX 32767
#define USHRT_MAX 65535

// Use a subtraction to avoid intermediate overflows
#define INT_MIN (-2147483647-1)
#define INT_MAX 2147483647
#define UINT_MAX 4294967295U

#define LONG_MIN (-9223372036854775807L-1)
#define LONG_MAX 9223372036854775807L
#define ULONG_MAX 18446744073709551615UL

#define LLONG_MIN LONG_MIN
#define LLONG_MAX LONG_MAX
#define ULLONG_MAX ULONG_MAX

#endif
