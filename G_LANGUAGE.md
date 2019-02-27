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

   This command clearly bears a similarity with the C semicolon, which
   is used to close statements. In G there are no statements, so there
   is no need to close them; as a result, in general `;` commands are
   only really required when you need to call a non-stack
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

The following non-stack commands are supported. When they are
executed, the stack must be empty (and, correspondingly, they leave it
empty).

 * **Code block**
 
 * **Local variable definition**

 * **Conditional block**

 * **Repeated block**
