#ifndef __ERRNO_H
#define __ERRNO_H

int __errno = 0;

#define errno __errno

// Defined by C standard
#define EDOM 1
#define EILSEQ 2
#define ERANGE 3

// Defined by POSIX
#define EINVAL 50
#define ENOENT 51

// Defined by me
#define ENOTIMPL 100

#endif
