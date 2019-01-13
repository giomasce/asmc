
#undef assert

#ifdef __ASMC_COMP__

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

#endif

#ifdef __TINYC__

#ifdef NDEBUG
#define assert(condition) ((void)0)
#else
#define assert(condition) ((void)((condition) || __assertion_failed(#condition, __func__, __FILE__, __LINE__)))
#endif

#undef _force_assert
#define _force_assert(condition) ((void)((condition) || __assertion_failed(#condition, __func__, __FILE__, __LINE__)))

#ifndef __ASSERTION_FAILED
#define __ASSERTION_FAILED

#include "stdio.h"
#include "stdlib.h"

int __assertion_failed(const char *a, const char *func, const char *file, int line) {
    fprintf(stderr, "ASSERTION FAILED in function %s at %s:%d: %s\n", func, file, line, a);
    abort();
}

#endif

#endif
