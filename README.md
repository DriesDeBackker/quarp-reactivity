# Quarp

A library for distributed reactiive programming with consistency guarantees in the spirit of QUARP. (https://haslab.uminho.pt/joseproenca/files/quarp.pdf)

Features fifo (no guarantee), glitch-freedom and logical clock synchronization as guarantees.

Can easily be extended with new guarantees if so desired by adding an implementation for the necessary operations in the Context module.

Built on top of and integrated with Observables Extended, a Reactive Extensions library for Elixir (https://github.com/DriesDeBackker/observables-extended).

This library was developed mainly for academic purposes, namely for exploring distributed reactive programming (for the IoT) with consistency guarantees.

## Installation

If [available in Hex](https://hex.pm/docs/publish), the package can be installed
by adding `quarp` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:quarp, "~> 1.0"}
  ]
end
```