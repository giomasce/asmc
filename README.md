# `asmc`, a bootstrapping OS with minimal binary seed

`asmc` is a rather extremely minimal operating system, whose binary
seed (the compiled machine code that is fed to the CPU when the system
boots) is very small (less than 10 KiB). Such compiled code is enough
to contain a minimal IO environment and compiler, which is used to
compile a more powerful environment and compiler, further used to
compile even more powerful things, until a fully running system is
bootstrapped. In this way nearly any code running in your computer is
compiled during the boot procedure, except the the initial seed that
ideally is kept as small as possible.

This at least is the plan; from the moment we are not yet at the point
where we manage to compile a real system environment. However, work is
ongoing (and you can contribute!).

The name `asmc` indicates two of the most prominents languages used in
this process: Assembly (with which the initial seed is written) and C
(one of the first targets we aim to). The initial plan was to embed an
Assembly compiler in the binary seed and then use Assembly to produce
a C compiler. In the end a different path was devised: the initial
seed is written in Assembly and embeds a G compiler (where G is a
custom language, sitting something between Assembly and C, conceived
to be very easy to compile); the G compiler is then use to produce a C
compiler. Assembly is never directly used in this chain, although of
course continuously behind the curtains.

## What is inside this repository

 * `lib` contains a very small kernel, designed to run on a i386 CPU
   in protected mode (with a flat memory model and without memory
   paging). The kernel offers an interface for writing to the console
   and to the serial port, a simple read-only ramdisk and some library
   routines for later stages.

   The kernel can be booted with multiboot, or can simply be loaded at
   1 MB and jumped in at its very beginning. The ramdisk must be
   appended to it in the `ar` format.

   The kernel must be compiled with payload, inside which it jumps
   after loading. Three payloads are provided, detailed later.

   In this directory there are also some C files that in theory enable
   you to host a payload directly in a Linux process. They were mostly
   useful in the beginning to test the code in a more friendly
   environment than a virtual machine, but they are far from being
   perfect and not very useful nowadays.

 * `empty` is just an empty test payload. It prints a message and then
   stop. Not very funny.

 * `asmasm` is an Assembly compiler written in Assembly, which can be
   used as a payload for the kernel, in order to make a small
   operating system that is just able to compile others Assembly
   programs to expand its capabilities. Once `asmasm` is loaded, it
   compiles the file `main.asm` and then jumps to the label `main`.
   `asmasm` is able to compile itself.

   `asmasm` supports only a subset of the x86 Assembly syntax and some
   NASM-styled directives. It definitely will not be able to compile
   any random Assembly program, if you do not reduce the program to
   the accepted syntax beforehand. As everything else in the binary
   seed, it is designed to be as simple and small as possible, and to
   contain the minimal tools required to build later stages that can
   do more grandiose things.

 * `asmg` is an G compiler written in Assembly. G is a custom language
   I invented for this project, described below in more details. As
   soon as it is ready, it compiles the file `main.g` and jumps to
   `main`. Here is where most of the development is concentrated
   nowadays. `asmg` can be compiled by `asmasm`.

   There are quite a few G sources available: besides a few C-styled
   library routines, there are an Assembly compiler and a C
   compiler. The Assembly compiler should be nearly ready to compile a
   lighly patched version of the FASM assembler, although this has
   never actually been done. The C compiler is still in development,
   but it is already able to compile some simple C
   programs. Eventually I hope to make it able to compile some real C
   compiler, like tcc, so that an actual toolchain can be boostrapped.

 * `boot` contains a simple bootloader that can be used to boot all of
   the above if you do not want to use GRUB (in the minimalistic style
   of the rest of the project). For the moment is cannot be compiled
   with `asmasm`, because it must use some system level opcodes that
   are not supported by `asmasm`, so you have to use NASM. Also, while
   it works under QEMU, it is definitely not bare metal proven. In the
   future it might be nice to make it a viable alternative to GRUB, so
   that `asmc`'s tiny binary seed is not tainted by megabytes of GRUB
   binaries.

 * `attic` and `cc` contains some earlier test code, that is not used
   any more and it is also probably broken. `staging.c` and
   `gstaging.c` are the original implementations of `asmasm` and
   `asmg` in C, used as a basis to write the Assembly code. `cc.c` and
   `cc2.c` are two stages of a test C compiler written in C, that was
   aborted halfway when I begun to work on the C compiler written in
   G.

 * `test` contains some test programs for the Assembly and C compilers
   contained in `asmg`.

## Design considerations

Ideally everything in `lib`, `asmasm` and `asmg` should be as simple
and small as possible. Since that is the part that must be already
build when the system boots, it should be verifiable by hand, i.e., it
should be so simple that a human being can take a printout of the code
and of the binary hex dump and check opcode by opcode that the code
was translated correctly. This is very tedious, so everything that is
not strictly necessary for building later stages should be moved to
later stages.

All other design criteria are of smaller concern: in particular
efficiency is not a target (all first stages compilers are definitely
not efficient, both in terms of their execution time and of the
generated code; however, ideally they are meant to be dropped as soon
as a real compiler is built).

Also coding style is very inhomogeneus, mostly because I am working
with languages with which I had very small prior experience before
starting this project (I had never written more than a few Assembly
lines together; the G language did not even exist when I started this,
because I invented it, so I could not possibly have prior
experience). During writing I established my own style, but never went
back to fix already written code. So in theory looking at the style
you can probably reconstruct the order in which a wrote code.

## The G language

My initial idea, when I wrote `asmasm`, was to embed an Assembly
compiler in the initial seed and then use Assembly to write a C
compiler. At some point I realized that bridging the gap between
Assembly and C with just one jump is very hard: Assembly is very low
level, and C, when you try to write its compiler, is much higher level
that one would expect in the beginning. At the same time, Assembly is
harder to compile properly then I initially expected: there are quite
some syntax variations and opcode encoding can be rather quircky. So
it is not the ideal thing to put in the binary seed.

Then I set out to invent a language which could offer a somewhat C
like writing experience, but that was as simple as possible to parse
and compile (without, of course, pretending to do any optimization
whatsoever). What eventually came out is the G language.

In my experience, and once you have ditched the optimization part, the
two difficult things to do to compile C are parsing the input (a lot
of operators, different priorities and syntaxes) and handling the type
system (functions, pointers, arrays, type decaying, lvalues, ...). So
I decided that G had to be C without types and without complicated
syntax. So G has just one type, which is the equivalent of `int` in C
and is also used for storing pointers, and expressions are written in
reverse Polish notation, so it is basically a stack machine.
