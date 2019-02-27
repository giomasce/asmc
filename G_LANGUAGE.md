# The G language

The G language is conceived to be logically as similar as possible to
a reasonable subset of C, while at the same time being easy to parse
and removed of features that are unessential to bootstrapping.

In G all variables have the same type, which is analogous to the `int`
type in C (although signedness is not defined: it is defined by
operators) and corresponds to the native integer type available on the
machine. It is used both as integer and as pointer. Since there is
only one type, function signatures are entirely defined by the number
of parameters they accept.

Each G file must only contains printable and whitespace ASCII
characters. They are assembled into tokens, each of which is either a
collection of non-whitespace characters bounded by whitespace
characters, or a string of characters bounded by `"`
guards. Whitespace characters (except those in strings) are irrelevant
and are dropped after tokenization. Comments are introduced by a `#`
(except those in strings) and continue to the end of the line.

## Top level structure

In a G source code, the following constructions are available.

 * **Constant definition**

        const NAME VALUE

   declares a compile-time constant with name `NAME` and value `VALUE`
   (which can be a previously defined constant, a decimal expression
   or a hexadecimal expression). Constants are not materialized into
   variables, but have the same type, so cannot contain values out of
   the native integer type bounds.

   Examples:

        const DOZEN 12
        const BYTE_MAX 0xff

 * **Global variable definition**

        $NAME

   defines a global variable called `NAME`, which is initialized to
   zero. There must be no space between the dollar sign and the name
   (i.e., they have to be in the same token).

   Example:

        $global_var

 * **Function declaration**

        ifun NAME PARAM_NUM

   declares a function named `NAME` with `PARAM_NUM` parameters
   without defining it. I will have to be matched by a later (or also
   earlier, although it is useless in this case) function definition
   (introduced with `fun`). The same function can be declared as many
   times as one wish, as long as all declarations have the same number
   of parameters (which must also be equal to the number of parameters
   in the function definition).

   Examples:

        ifun setup 0
        ifun sum_two_numbers 2

 * **Function definition**

        fun NAME PARAM_NUM { BODY }

   defines a function names `NAME` with `PARAM_NUM` parameters. `BODY`
   must be the code to be executed when the function is called (see
   "Function body" below).

## Function body

The body of a function is a sequence of commands that are to be
executed by a stack machine. At the beginning of the function the
stack is empty, but there is not obligation to leave it empty at the
end. In general each command pops a few (possibly zero) operands, does
some computation with them and pushes the result. All stack elements
have the same type as any variable.

Multiplexed with stack commands, other commands are available to
manage execution flow or introduce local variables. In general, all
non-stack commands require the stack to be empty at their point of
execution.

In particular, the following stack commands are supported.

 * **Push a constant value** Writing an integral value (either in
   decimal or hexadecimal form) causes it to be pushed on the stack.

 * **Push variable value** Writing a variable name (either local or
   global) causes its current value to be pushed on the stack.

 * **Call a function by name** Writing a function name causes a number
   of arguments equal to the number of parameters the function accept
   to be popped from the stack. The function is then called with such
   parameters passed to it, and its return value is then pushed on the
   stack. All functions always return a value, there is no concept of
   a function returning `void`. If this value has no meaning, it is up
   to the caller to ignore it.

 * **Push variable address** Writing a variable or function name
   prepended by a `@` sign (without spaces: they have to be in the
   same token) causes its address to be pushed on the stack.

 * **Flush the stack** Writing a single `;` character causes the stack
   to be flushed (i.e., all values are popped and discarded). This is
   required before using non-stack commands, like execution flow
   control and variable introduction commands.

 * **Return from function** Writing a token `ret` causes the function
   to immediately return. If the stack is not empty, its top value is
   the function return value. If the stack is empty, the return value
   is unspecified.

The following non-stack commands are supported. When they are
executed, the stack must be empty (and, correspondingly, they leave it
empty).

 * **Code block** At any point a scoped block can be begun with the
   command `{` and closed with the corresponding `}`. All variables
   definitions inside the block expire when the block is closed. The
   stack does not need to be empty at the end of the block, but if it
   is not, it is flushed.

 * **Local variable definition** Writing `$NAME` a new variable with
   name `NAME` is introduced. Its initial value is unspecified
   (differently from global variables).

 * **Conditional block** The `if` token introduces a conditional
   block. It must be followed by one or more stack commands (except
   `ret`) and then by a code block, defined as above. When the
   conditional block is executed, first the guard stack commands are
   evaluated and must leave exactly one value in the stack: if such
   value is zero, control is directly trasfered to the end of the
   block. If not, the block is executed normally. Differently from C,
   the `if` command must guard a block; it cannot guard a single
   expression. Optionally, the token `else` followed by another block
   can appear. That block is executed if the initial guard evaluates
   to zero and skipped if it does not.

 * **Repeated block** Then `while` token introduces a repeated
   block. Its syntax is identical to the conditional block, except for
   the usage of `while` instead of `if`. Its semantic is also
   identical, except that at the end of the block execution the guard
   expression is evaluated again, and if it still non-zero, the block
   is executed again. The `else` block cannot appear in this case.

   G does not directly support `for` blocks and `continue`, `break`
   and `goto` statements. If needed, they have to be emulated with
   appropriate flags.

The function's formal parameters are not directly available as named
variables. However, they can be retrieved with the `param` predefined
function, described below.

## Predefined functions

The following functions are always available in a G program, without
having to be manually defined.

 * `=` (2 arguments) assigns the latest pushed argument to the
   variable at the address specified by the earliest pushed
   argument. It is important to notice that this is not completely
   equivalent to the C assignement operator, because G has no
   equivalent for the C lvalue concept. Thus `a b =` is rather
   equivalent to C's `*(int*)a = b`. If you want to assign the value
   of `b` to `a`, then you need to write `@a b =` in G, which becomes
   equivalent to C's `*(int*)&a = b`.

 * `param` (1 argument) returns the `n`-th formal parameter to the
   enclosing function, where `n` is the value passed to `param`. If
   `n` is larger or equal then the number of parameters, the behaviour
   is unspecified. The zeroth parameter is the one that was pushed
   *last* on the stack before calling the enclosing
   function. Therefore in the following snippet:

        fun test 2 {
          $a $b
          @a 0 param = ;
          @b 1 param = ;
        }

        fun test2 0 {
          0 1 test ;
        }

   `a` will have value `1` and `b` will have value `0` inside `test`.

 * `+` (2 arguments) returns the sum of its two arguments.

 * `-` (2 arguments) returns the difference of its two arguments (the
   earliest pushed minus the latest pushed).

 * TODO

## Common coding suggestions

This section is not normative, but G programmers are encouraged to
follow it so that G programs remain as readable as possible.

 * The `;` command clearly bears a similarity with the C semicolon,
   which is used to close statements. In G there are no statements, so
   there is no need to close them; as a result, in general `;`
   commands are only really required when you need to call a non-stack
   command. However, it is suggested to still use them in the C way,
   to improve readability and to drop the stack as soon as it is not
   needed anymore (this also prevents leftover stack elements to be
   used in a successive unrelated expression).

   For example, the following code assignes `0` to the variable `a`
   and `1` the the varible `b`:

        @a 0 = ;
        @b 1 = ;

   The first semicolon (and possibily the second one too, depending on
   what comes later) can be removed without changing the program
   behaviour:

        @a 0 =
        @b 1 = ;

   In this second case, the second assignement is executed while still
   having the value of `a` at the bottom of the stack. Thus the
   program is still correct, but for the reasons above the first
   snippet is encouraged. Incidentally, newlines are irrelevant too:
   the same code could have written, with or without the semicolon, on
   one line:

        @a 0 = @b 1 = ;

   And, of course, this is even less encouraged.

 * The usage of the `param` function might be a bit non-obvious,
   because it causes parameters to materialize inside the function in
   a way that might appears to be the "opposite" of what might seem
   sensible. The suggested idiomatic way to use `param` in thus the
   following: suppose that you want to define a function analogous to
   the C declaration

        int func(int a, int b, int c);

   Then it is suggested to define it in G in this way:

        fun func 3 {
          $a
          $b
          $c
          @a param 2 = ;  # Notice param arguments are in
          @b param 1 = ;  # decreasing order
          @c param 0 = ;

          # Do not use param anymore in function body; just use a, b
          # and c
        }

   and call it by pushing arguments on the stack in the same order
   they appear in the C declaration:

        fun func2 0 {
          0 1 2 func ;
        }

   `a` will take value `0`, `b` will take value `1` and `c` will take
   value `2` inside `func`.

   Also, the reference G compiler will produce for `func` machine code
   that is ABI-compatible with the C declaration for `func` if the C
   compiler uses `cdecl` calling conventions, which permits easy
   interaction between C and G in later stages of `asmc`.

 * G's very simple type system, while allowing a very simple syntax
   and compiler, completely leaves the burden of organizing structured
   data types on the programmer. Fortunately the task is not that
   difficult with a little bit of code organization (which is, in the
   end, not very different from what happens in a C program, except
   that you do not have the syntactic sugar coating). Suppose that you
   need a structure like this one in C:

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

   Then, using `ptr` to denote a pointer to this structure, the
   following C code:

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

   The library routines `take` and `take_addr` are defined in
   `utils.g` and do the right thing here (`take_addr` is actually
   completely equivalent to `+` and `take` is just `+` followed by
   dereferencing; it is useful to give them different names to remark
   their meaning).

   The G syntax is a bit more verbose and requires some care in
   maintaining the offset tables for all structures (be careful not to
   get confused between multiples of 4 and feel free to use
   hexadecimal if it makes things easier for you), but all in all if
   you know how to do things in C, converting to G is rather
   straightforward.

## Examples

Let us discuss a few simple G programs and provide their C equivalents
to better illustrate them.

    fun sum_two_numbers 2 {            int sum_two_numbers(int p1, int p0) {
      $x                                 int x;
      $y                                 int y;
      @x 1 param = ;                     x = p1;
      @y 0 param = ;                     y = p2;

      $sum                               int sum;
      @sum x y + = ;                     sum = x+y;
      sum ret ;                          return sum;
    }                                  }

Incidentally, `sum_two_numbers` does exactly the same thing as the
built-in function `+`, but it was an easy starting example.

    const FROM 20                      #define FROM 20
    const TO 0x64                      #define TO 0x64

    ifun sum_number 2                  int sum_numbers(int, int);

    fun main 0 {                       int main(void) {
      "The sum of numbers from "         platform_log("The sum of numbers from ", 1);
        1 platform_log ;
      FROM itoa 1 platform_log ;         platform_log(itoa(FROM), 1);
      " to " 1 platform_log ;            platform_log(" to ", 1);
      TO itoa 1 platform_log ;           platform_log(itoa(TO), 1);
      " is " 1 platform_log ;            platform_log(" is ", 1);
      FROM TO sum_numbers itoa           platform_log(itoa(sum_numbers(FROM, TO)), 1);
        1 platform_log ;
      "\n" 1 platform_log ;              platform_log("\n", 1);
    }                                  }

    # Return the sum of numbers        // Return the sum of numbers
    # in an interval                   // in an interval
    fun sum_numbers 2 {                int sum_numbers(int p1, int p0) {
      $from                              int from;
      $to                                int to;
      @from 1 param = ;                  from = p1;
      @to 0 param = ;                    to = p0;

      $i                                 int i;
      $sum                               int sum;
      @i from = ;                        i = from;
      @sum 0 = ;                         sum = 0;
      while i to <= {                    while i <= to {
        @sum sum i + = ;                   sum = sum + i;
        @i i 1 + = ;                       i = i + 1;
      }                                  }

      sum ret ;                          return sum;
    }                                  }

Of course C has quicker expressions like `+=` and `++`, but I did not
use them in this example to better explain the analogy with G. The
function `itoa` returns a number formatted as a decimal string, while
the function `platform_log` dump a string to the console.
