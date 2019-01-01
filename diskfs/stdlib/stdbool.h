#ifndef __STDBOOL_H
#define __STDBOOL_H

// This is technically non-compliant, because the bool time requires
// specific compiler support; for the moment we just emulate it with
// int.

#define bool int
#define true 1
#define false 0
#define __bool_true_false_are_defined 1

#endif
