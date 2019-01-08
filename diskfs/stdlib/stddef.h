#ifndef __STDDEF_H
#define __STDDEF_H

#include "asmc_types.h"

typedef int ptrdiff_t;

// From PDClib
#define offsetof( type, member ) ( (size_t) &( ( (type *) 0 )->member ) )

#endif
