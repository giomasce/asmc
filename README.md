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
