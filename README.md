![build](https://github.com/R-unic/cosmo/actions/workflows/crystal.yml/badge.svg)
# Cosmo

Cosmo is a statically-typed programming language written in pure Crystal.<br>
We have an [extension for VS code](https://marketplace.visualstudio.com/items?itemName=cosmo.vscode-cosmo) ([source](https://github.com/R-unic/vscode-cosmo)), however it currently only features syntax highlighting.

## Things I Gotta Do

- Modules
- Performance boosts lol
- Multiple assignment
- Unary `++` and `--` operators
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
  * intersections

## Things I Might Do

- Make into a VM or compiler
- C bindings

## Gotchas

### Table type definitions
Type definitions for tables can be amibigous.<br>
I plan to fix this in the future. For example:
```go
string->string->string my_table
```
Currently, this type resolves to a table with `string` keys, and `string->string` values.<br>
Using a type alias here is broken currently, but is clearly what makes sense to use.<br>
In the future (but not right now), this code should be valid:
```crystal
type MyTable = string->string
MyTable->string weird_table = {
  [{"some" -> "thing"}] -> "hello world"
}
puts(weird_table[{"some" -> "thing"}]) ## hello world
```
Another issue is with arrays.
```go
string->string[]
```
Is this type an array of `string->string` tables? Or is it a table of strings to `string[]`s?<br>
Then again, you can always just use the `any` type to bypass any of this and let hell run loose at runtime.<br>
As stated before though, I would like to fix this.

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
