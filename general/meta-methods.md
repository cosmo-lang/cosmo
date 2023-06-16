---
description: >-
  Meta methods are methods that can be defined on classes to overload operators
  or other specific behavior.
---

# Meta methods

Below is a list of each meta method name along with it's corresponding operator (or functionality). Each operator listed is binary unless otherwise stated.

### Operator overloading

* `add$` - `+`
* `sub$` - `-`
* `mul$` - `*`
* `div$` - `/`
* `idiv$` - `//`  - same as `(a / b).floor`
* `pow$` - `^` - exponentation, not XOR
* `mod$` - `%`
* `gte$` - `>=`
* `lte$` - `<=`
* `unm$` - `-` (unary)
* `unp$` - `+` (unary)
* `size$` - `#`
* `bnot$` - `~` (unary)
* `band$` - `&`
* `bor$` - `|`
* `bshr$` - `>>`
* `bxor$` - `~`
* `bshl$` - `<<`

### Other

* `to_string` - calls when casting to string (e.x. `<string>abc` will call `abc->to_string` if it's a class instance)
* `is_in$` - calls when using an `is in` expression (e.x. `foo is in bar` will call `bar->is_in$(foo)`)

