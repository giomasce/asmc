#ifndef __SIGNAL_H
#define __SIGNAL_H

#include "errno.h"
#include "sys/types.h"

typedef int sigset_t;

union sigval {
    int sival_int;
    void *sival_ptr;
};

typedef struct {
    int si_signo;
    int si_code;
    int si_errno;
    pid_t si_pid;
    uid_t si_uid;
    void *si_addr;
    int si_status;
    long si_band;
    union sigval si_value;
} siginfo_t;

struct sigaction {
    void (*sa_handler)(int);
    sigset_t sa_mask;
    int sa_flags;
    void (*sa_sigaction)(int, siginfo_t*, void*);
};

#define SA_SIGINFO (1 << 0)
#define SA_RESETHAND (1 << 1)

typedef struct {
    int gregs[2];
} mcontext_t;

#define REG_EIP 0
#define REG_EBP 1

typedef struct {
    void *ss_sp;
    size_t ss_size;
    int ss_flags;
} stack_t;

typedef struct ucontext_t {
    struct ucontext_t *uc_link;
    sigset_t uc_sigmask;
    stack_t uc_stack;
    mcontext_t uc_mcontext;
} ucontext_t;

int sigemptyset(sigset_t *set) {
    *set = 0;
}

int sigaction(int sig, const struct sigaction *act, struct sigaction *oact) {
    errno = ENOTIMPL;
    return -1;
}

#define SIGFPE 1
#define SIGBUS 2
#define SIGSEGV 3
#define SIGILL 4
#define SIGABRT 5

#define FPE_INTDIV 1
#define FPE_FLTDIV 2
    
#endif
