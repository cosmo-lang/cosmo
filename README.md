![build](https://github.com/R-unic/cosmo/actions/workflows/crystal.yml/badge.svg)
# Cosmo

Cosmo is a statically-typed programming language written in pure Crystal.<br>
We have an [extension for VS code](https://marketplace.visualstudio.com/items?itemName=cosmo.vscode-cosmo) ([source](https://github.com/R-unic/vscode-cosmo)), however it currently only features syntax highlighting.

## Things I Gotta Do

- Package manager
- Performance boosts lol
- Multiple assignment
- Somehow typecheck blocks before execution
- Fix weird expression parsing (`[0].123` evaluates to 0.123??)
- Literal wrapper classes (vector, table)
- Interfaces
- Classes
  * single inheritance
  * mixins
  * visibilities
  * methods
  * `$` (this)
- Better type system
  * casting
  * intersections

## Things I Might Do

- Make into a VM or compiler
- C bindings

## Installation

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
