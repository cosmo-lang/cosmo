![build](https://github.com/cosmo-lang/cosmo/actions/workflows/crystal.yml/badge.svg)
# Cosmo

Cosmo is a statically-typed programming language written in pure Crystal.<br>
We have an [extension for VS code](https://marketplace.visualstudio.com/items?itemName=cosmo.vscode-cosmo) ([source](https://github.com/R-unic/vscode-cosmo)), however it currently only features syntax highlighting and code snippets.

## Installation

Download the [Cosmo Installer](https://github.com/cosmo-lang/cosmo-installer/releases) and run it.

## Things I Gotta Do

### Features
- Grammar
  - Regexes
  - Endless (and beginless?) range literals
  - `use * from "mod" as Name`
  - `is in` for tables
    * `is_in$` meta method?
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
    * an actual type pass
    * generics
    * type inference
    * casting union types
    * implicit conversions
    * intersection types
- Other
  - Filesystem library
  - `Spread` type
  - Some form of multithreading
  - `char` intrinsic methods
  - Intrinsic methods for all datatypes (inherit from a base type)
  - REPL supports multiline source

### Fixes
- Performance boosts lol
- Chained method calls with optional parentheses (`.split('.').first.split('?').first`)

### Tests
- Expectation of errors in parser spec

### Refactorings
(empty)

### Meta
- Package manager ([WIP](https://github.com/cosmo-lang/stars))
- Documentation generator?
- Linting/language server
- Highlight function definition names without parentheses
- Explain module system in Wiki

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

Have any questions or comments? DM me on Discord: `runic#5997`

## Contributors

- [R-unic](https://github.com/R-unic) - creator and maintainer
- [quasar098](https://github.com/quasar098)