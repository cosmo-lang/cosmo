![build](https://github.com/cosmo-lang/cosmo/actions/workflows/crystal.yml/badge.svg)
# Cosmo

Cosmo is a statically-typed programming language written in pure Crystal.<br>
We have an [extension for VS code](https://marketplace.visualstudio.com/items?itemName=cosmo.vscode-cosmo) ([source](https://github.com/R-unic/vscode-cosmo)), however it currently only features syntax highlighting.

## Installation

Download the [Cosmo Installer](https://github.com/cosmo-lang/cosmo-installer) and run it.

## Things I Gotta Do

### Features
- Enums
- Utility methods for tables
- Stack trace
- Allow throwing class instances that inherit from a base `Exception` class
- Regexes
- `try..catch` statements
- `none` accessing (`hello&.world` evaluates to `none` if `hello == none`)
- Intrinsic methods for all datatypes (inherit from a base type)
- Decorators
- Interfaces
- Namespaces
- Classes
  * single inheritance
  * mixins
  * static/protected members
- Better type system
  * bound expressions
  * type inference
  * generics
  * casting union types
  * implicit conversions
  * intersection types

### Fixes
- Accessing private class members in public class methods
- Performance boosts lol
- Weird expression parsing (`[0].123` evaluates to 0.123??)
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
- Make a Cosmo->C compiler
- C bindings

## Contributing

1. Fork it (<https://github.com/R-unic/cosmo/fork>)
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Test your code (`make test`)
5. Push to the branch (`make publish`)
6. Create a new Pull Request

## Contributors

- [R-unic](https://github.com/R-unic) - creator and maintainer
