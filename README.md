![build](https://github.com/cosmo-lang/cosmo/actions/workflows/crystal.yml/badge.svg)
# Cosmo

Cosmo is a statically-typed interpreted programming language written in pure Crystal.<br>
We have an [extension for VS code](https://marketplace.visualstudio.com/items?itemName=cosmo.vscode-cosmo) ([source](https://github.com/R-unic/vscode-cosmo)), however it currently only features syntax highlighting and code snippets.

## Installation

Download the [Cosmo Installer](https://github.com/cosmo-lang/cosmo-installer/releases) and run it.

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

## Things I Might Do

- Named arguments
- Make a Cosmo->C compiler
- C bindings

## Things I Gotta Do

### Features
- Grammar
  - Regexes
  - Endless (and beginless?) range literals
  - `do_something for every int x in vec`
  - `typeof`
  - Enums
  - Decorators
  - Interfaces
  - Namespaces
  - Classes
    * single inheritance
    * mixins
    * static/protected members
  - Rewrite type system
    * bound expressions (!!)
    * an actual type pass
    * generics
    * type inference
    * casting union types
    * implicit conversions
    * intersection types
- Other
  - `+` operator for vectors, same functionality as `Vector->combine`
  - Filesystem library
  - `string` and `char` to hex conversions (e.x. `<uint>'f' == 15`)
  - Some form of multithreading
  - Intrinsic methods for all datatypes (inherit from a base type)
  - REPL supports multiline source

### Fixes
- Performance boosts lol
- Segfaults
  * passing `$`?
  * `<float[]>[1,2,3]`
- Class instance variables available outside of `$`
- Throw if same module was imported twice
- `["a.b.c"].first.split('.')` tries to access `["a.b.c"].first` instead of `["a.b.c"].first()` because of the `split` call with parentheses (bug)

### Tests
- Chained method calls with optional parentheses (e.x. `["a.b.c"].first.split('.')`)
- Expectation of errors in parser spec (e.x. `()` throws `Invalid syntax ')': Expected an expression`)

### Refactorings
(empty)

TODO: http server routing stuff

### Meta
- Package manager ([Stars](https://github.com/cosmo-lang/stars) + [StarsAPI](https://github.com/cosmo-lang/stars-api)) (WIP)
- Documentation generator?
- Language server
- Highlight function definition names without parentheses

### Docs
- Explain module system in Wiki
- Update some of the screenshots on the Wiki
- Document intrinsics