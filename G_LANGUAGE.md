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
