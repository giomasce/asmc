#ifndef __SETJMP_H
#define __SETJMP_H

typedef struct {
  unsigned long eax;
  unsigned long ebx;
  unsigned long ecx;
  unsigned long edx;
  unsigned long esi;
  unsigned long edi;
  unsigned long ebp;
  unsigned long esp;
  unsigned long eip;
} jmp_buf;

#define setjmp(env) (__handles->platform_setjmp(&(env)))
void longjmp(jmp_buf env, int status);

#include "asmc.h"

void longjmp(jmp_buf env, int status) {
  if (status == 0) status = 1;
  __handles->platform_longjmp(&env, status);
}

#endif
