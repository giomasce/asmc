#ifndef __STDARG_H
#define __STDARG_H

typedef struct {
    int ptr;
} va_list;

int __postadd(int *x, int y) {
    int r = *x;
    *x += y;
    return r;
}

#define va_start(list, param) ((void)(list.ptr = (int)&(param) + sizeof(param)))
#define va_arg(list, type) (*(type*)__postadd(&list.ptr, sizeof(type)))
#define va_copy(dest, src) ((void)(dest.ptr = src.ptr))
#define va_end(list) ((void)0)

#endif
