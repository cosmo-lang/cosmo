![build](https://github.com/cosmo-lang/cosmo/actions/workflows/crystal.yml/badge.svg)
# Cosmo

Cosmo is a statically-typed programming language written in pure Crystal.<br>
We have an [extension for VS code](https://marketplace.visualstudio.com/items?itemName=cosmo.vscode-cosmo) ([source](https://github.com/R-unic/vscode-cosmo)), however it currently only features syntax highlighting.

## Installation

Download the [Cosmo Installer](https://github.com/cosmo-lang/cosmo-installer/releases) and run it.

## Things I Gotta Do

### Features
- Grammar
  - `try..catch` statements (can't do until you can throw more than just strings)
  - Regexes
  - Enums
  - Decorators
  - Interfaces
  - Namespaces
  - Classes
    * single inheritance
    * mixins
    * static/protected members
  - Better type system
    * bound expressions (!!)
    * type inference
    * generics
    * casting union types
    * implicit conversions
    * intersection types
- Other
  - Utility methods for tables
  - Stack trace
  - Allow throwing class instances that inherit from a base `Exception` class (can't do until stack traces exist)
  - Intrinsic methods for all datatypes (inherit from a base type)

### Fixes
- Performance boosts lol
- Accessing private class members in public class methods
- Weird expression parsing (`[0].123` evaluates to 0.123??)
- Handle infinite recursion
  * macro function to set recursion depth limit

### Tests
- Literal value intrinsic methods (`Vector->map`, `string->split`, etc)

### Refactorings
(empty)

### Meta
- Package manager ([WIP](https://github.com/cosmo-lang/stars))
- Documentation generator?
- Linting/language server
- Highlight function names without parentheses
- Put snippets into VSC extension

## Things I Might Do

- Named arguments
- Make a Cosmo->C compiler
- C bindings

## Contributing

1. [Fork it](https://github.com/R-unic/cosmo/fork)
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Test your code (`make test`)
5. Push to the branch (`make publish`)
6. Create a new [Pull Request](https://github.com/cosmo-lang/cosmo/pulls)

## Contributors

- [R-unic](https://github.com/R-unic) - creator and maintainer
