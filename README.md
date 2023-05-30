![build](https://github.com/cosmo-lang/cosmo/actions/workflows/crystal.yml/badge.svg)
# Cosmo

Cosmo is a statically-typed programming language written in pure Crystal.<br>
We have an [extension for VS code](https://marketplace.visualstudio.com/items?itemName=cosmo.vscode-cosmo) ([source](https://github.com/R-unic/vscode-cosmo)), however it currently only features syntax highlighting.

## Things I Gotta Do

### Features
- Enums
- Utility methods for tables
- Stack trace
- String stuff
 * Multiline strings
 * Regexes
- Allow throwing class instances that inherit from a base `Exception` class
- `try..catch` statements
- `none` coalescing/accessing
- Intrinsic methods for all datatypes (inherit from a base type)
- Decorators
- Interfaces
- Namespaces
- Classes
  * single inheritance
  * mixins
  * static/protected members
- Better type system
  * type inference
  * generics
  * casting union types
  * implicit conversions
  * intersections

### Fixes
- Performance boosts lol
- Weird expression parsing (`[0].123` evaluates to 0.123??)
- Segfaults
  * e.x. `x << [1]`
- Handle infinite recursion
  * macro function to set recursion depth limit

### Refactorings
(empty)

### Meta
- Package manager ([WIP](https://github.com/cosmo-lang/stars))
- Documentation generator
- Linting/language server
- Highlight function names without parentheses

## Things I Might Do

- Named arguments
- Make declarations immutable by default and replace `const` with `mut`
- Make into a compiler or bytecode interpreter
- C bindings

## Installation

### Linux/OSX
1. Install [Crystal](https://crystal-lang.org/install/).
2. Run `sudo make install`.
3. Assert everything is working by running `cosmo -h`

## Contributing

1. Fork it (<https://github.com/R-unic/cosmo/fork>)
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Test your code (`make test`)
5. Push to the branch (`make publish`)
6. Create a new Pull Request

## Contributors

- [R-unic](https://github.com/R-unic) - creator and maintainer
