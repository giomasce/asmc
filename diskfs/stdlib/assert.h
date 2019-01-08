
#undef assert

#ifdef NDEBUG
#define assert(condition) ((void)0)
#else
#define assert(condition) ((void)((condition) || __assertion_failed(#condition)))
#endif

#undef _force_assert
#define _force_assert(condition) ((void)((condition) || __assertion_failed(#condition)))

#ifndef __ASSERTION_FAILED
#define __ASSERTION_FAILED

#include "stdio.h"
#include "stdlib.h"

int __assertion_failed(const char *a) {
    fputs("\nASSERTION FAILED: ", stderr);
    fputs(a, stderr);
    fputs("\n", stderr);
    abort();
}

#endif
