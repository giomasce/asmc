
# Metamath Zero logical model

While parsing a `.mm0` file, a Theory object is incrementally
constructed. A Theory object is characterized by the following
properties:

 * `sorts` (collection of Sort objects with different names)
 * `vars` (collection of Var objects with different names)

# Sort object

A Sort object is characterized by the following properties:

 * `name` (identifier)
 * `pure` (boolean)
 * `strict` (boolean)
 * `provable` (boolean)
 * `nonempty` (boolean)

# Var object

A Var object is characterized by the following properties:

 * `name` (identifier)
 * `sort` (identifier which appears as `name` of a previously defined Sort object)
 * `dep_vars` (collection of identifiers which appear as `name` of previously defined Var objects)
 * `starred` (boolean, which must be false if `dep_bars` is non empty)
