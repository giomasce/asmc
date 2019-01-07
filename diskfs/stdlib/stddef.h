#ifndef __STDDEF_H
#define __STDDEF_H

#include "asmc.h"

// From PDClib
#define offsetof( type, member ) ( (size_t) &( ( (type *) 0 )->member ) )

#endif
