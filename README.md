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
syntax. So G has just one type, which is the equivalent of a 32-bits
`int` in C and is also used for storing pointers, and expressions are
written in reverse Polish notation, so it is basically a stack
machine. Of course G is very tied to the i386 architecture, but it is
not meant to do much else.

### Ok, so what happens in a G program?

Let us illustrate it with an example:

    const FROM 20
    const TO 0x64

    ifun do_sum 2

    fun main 0 {
      "The sum of numbers from " 1 platform_log ;
      FROM itoa 1 platform_log ;
      " to " 1 platform_log ;
      TO itoa 1 platform_log ;
      " is " 1 platform_log ;
      FROM TO do_sum itoa 1 platform_log ;
      "\n" 1 platform_log ;
    }

    # Return the sum of numbers in an interval
    fun do_sum 2 {
      $from
      $to
      @from 1 param = ;
      @to 0 param = ;

      $i
      $sum
      @i from = ;
      @sum 0 = ;
      while i to <= {
        @sum sum i + = ;
        @i i 1 + = ;
      }

      sum ret ;
    }

Whitespace is always irrelevant except for separating tokens (it is
relevant in strings, though). Comments are introduced by `#`.

The keyword `const` introduces a numerical (signed 32-bits)
constant. All numbers can be expressed with decimal or hexadecimal
notation, prefixed by `0x`.

The keyword `ifun` introduces a function prototype, much like C's
function declaration without definition. Since there is only one type,
the function signature is completely described by the number of its
arguments, which is specified just after the name. Variadic arguments
are not supported.

The keyword `fun` introduces an actual function definition, whose body
is contained between curly braces as in C. In each function there is a
stack, which is empty when entering the function (there is no
requirement to leave it empty at the end).

Inside a function, the syntax `$name` introduces a new automatic
variable called `name` (again, the type is always a 32-bits
numbers). It does not touch the stack, but the stack must be empty
when using `$name`. If `name` is a local variable, the syntax `name`
pushes its value on the stack and the syntax `@name` pushes its
address on the stack. Similarly, writing a number just pushes its
value on the stack. Character and string literals are supported with a
C-like syntax (for strings the address is pushed on the stack). Most C
character escapes are supported (but octal and hexadecimals codes are
not).

If `name` is a function, the syntax `name` pops a number of values
from the stack equal to the number of parameters of `name`, then calls
`name` with those arguments and then pushes on the stack whatever
`name` returns. The first value popped from the stack is passed as the
last argument. Again, the syntax `@name` just pushes the function's
address on the stack.

The syntax `ret` returns immediately from the function. The returned
value is the last thing pushed on the stack if there is any, otherwise
it is just undefined (but something will be pushed on the caller's
stack anyway; in case, it is the caller's duty to ignore such
value). The syntax `;` (a semicolon) empties the stack, discarding all
its content. Note that tokenization in G is based on whitespace, so
the `;` must be separated from the previous (and following) token. It
is important to notice that, although the semicolon is used in the
example somewhat like in C programs to terminate statements, there is
no concept of statement in G language, and most semicolons in the
example program could actually be dropped without changing the
semantics of the program. However, dividing the program into logical
statements just as one would do for C and separating them with
semicolons is useful to reduce stack usage and avoid percolating of
stack values in unrelated statements, which can of course lead to
bug. And given how poor development and debugging tools for G are, you
definitely do not want to add new bug opportunities. The only places
where you actually have to use a semicolon is before a `$name` token,
because they need the stack to be empty.

At last G supports `if` and `while` constructs, which work exactly as
for C:

    if expr {
      ...
    } else {
      ...
    }

and

    while expr {
      ...
    }

The `else` part is optional for the `if`. The curly braces are never
optional and there is no `else if` construct. You have to actually
nest `if`s. In `expr` you have to put any sequence of tokens, and the
result of the expression if the last value pushed on the stack. There
are not `for`, `do`-`while`, `break`, `continue` and `goto`, although
`ret` can sometimes help with flow management.

Function arguments do not receive automatically a name, but can
retrieved with the `param` function, that pops a number and returns
the corresponding parameter. There is, at last, a syntax for indirect
function calling: `\number` will pop a function address and `number`
function arguments, and do a function call as above. The number must
be known at compile time, because of how the compiler is designed (as
usual, the point is making it as simple as possible).

There are not other primitive syntaxes: all the other tokens in the
example program, including `+` and `=`, are actually "standard"
library calls. They are very similar to C (except that they use
postfix notation), so probably there is little need to present them
one by one. It is however to be noted that `&&` and `||` do not have
the early termination semantics of C (because both operands are
evaluated even before G knows that they are to be fed to `&&` or
`||`). Also, since there is no concept of lvalue in G, the operator
`=` has a different meaning: it accepts two values, the first of which
is interpreted as the address of the destination operand and the
second of which is interpreted as the source operand. Thus `a b =` in
G is roughly equivalent to `*a = b` in C. That is way most of the
times the first operand of `=` is expressed with the syntax `@name`,
in order to extract the address. The dereferencing operation is named
`**`, in order to distinguish it from the multiplicaton `*`. It always
interpret its argument as a pointer to a 4-byte value. For
manipulating single bytes there are the operators `=c` and `**c`,
which work just as `=` and `**` except that assume that arguments are
pointers to single bytes (in particular `**c` zero extends the byte to
a 4-bytes value and `=c` copies that less significant byte to the
destination pointed by the pointer).

The functions called `platform_*` are simply `asmc`'s kernel routines
exposed to the G program. For example, `platform_log` logs a string to
the console and to the serial port (the other argument can be used to
specify a different stream, but basically only 1 is supported for the
moment). The function `itoa` convert a number to its decimal
representation, written in a static buffer pointed by its return
value.

### How to do structured data types?

G's very simple type system, while allowing a very simple syntax and
compiler, completely leaves the burden of organizing structured data
types on the programmer. Fortunately the task is not that difficult
with a little bit of code organization (which is, in the end, not very
different from what happens in a C program, except that you do not
have the syntactic sugar coating). Suppose that you need a structure
like this one in C:

    typedef struct {
      int first;
      int second;
      int third;
    } MyStruct;

You can use the following code in G:

    const MYSTRUCT_FIRST 0
    const MYSTRUCT_SECOND 4
    const MYSTRUCT_THIRD 8
    const SIZEOF_MYSTRUCT 12

Then, using `ptr` to denote a pointer to this structure, the following
C code:

    MyStruct *ptr;
    ptr = malloc(sizeof(MyStruct));
    ptr->first = 0;
    ptr->second = ptr->third;
    free(ptr);

is roughly equivalent to this G code:

    $ptr
    @ptr SIZEOF_MYSTRUCT malloc = ;
    ptr MYSTRUCT_FIRST take_addr 0 = ;
    ptr MYSTRUCT_SECOND take_addr ptr MYSTRUCT_THIRD take = ;
    ptr free ;

The library routines `take` and `take_addr` are defined in `utils.g`
and do the right thing here (`take_addr` is actually completely
equivalent to `+` and `take` is just `+` followed by dereferencing; it
is useful to give them different names to remark their meaning).

The G syntax is a bit more verbose and requires some care in
maintaining the offset tables for all structures (be careful not to
get confused between multiples of 4 and feel free to use hexadecimal
if it makes things easier for you), but all in all if you know how to
do things in C, converting to G is rather straightforward.
