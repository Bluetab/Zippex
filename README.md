# Zippex

A [Zipper](https://en.wikipedia.org/wiki/Zipper_%28data_structure%29) is a
representation of an aggregate data structure which allows it to be
traversed and updated arbitrarily. The `Zippex` module provides a generic
zipper for structures with tree-like semantics.

Zippex is inspired by other zipper implementations, notably:

 * [clojure.zip](https://clojuredocs.org/clojure.zip/zipper) - Clojure's zipper library
 * [inaka/zipper](https://github.com/inaka/zipper) - A generic Zipper implementation in Erlang
 * Exercism's [Zipper](https://exercism.io/tracks/elixir/exercises/zipper) exercise

## Installation

The package can be installed by adding `zippex` to your list of dependencies
in `mix.exs`:

```elixir
def deps do
  [
    {:zippex, "~> 1.0.0-rc.1"}
  ]
end
```

## Usage

The docs can be found at [https://hexdocs.pm/zippex](https://hexdocs.pm/zippex).

Also see Zippex [unit tests](https://github.com/Bluetab/Zippex/blob/master/test/zippex_test.exs)
for usage examples.
