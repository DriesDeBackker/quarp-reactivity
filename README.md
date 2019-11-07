# Quarp-reactivity

A library for distributed reactiive programming with consistency guarantees in the spirit of Quality Aware Reactive Programing for the IoT (QUARP) (https://haslab.uminho.pt/joseproenca/files/quarp.pdf)

Provides a DSL for reactive programming, made distributed by usage of the rp-middleware dependency.

Can be easily deployed to embedded devices using https://nerves-project.org

Features fifo (no guarantee), glitch-freedom and logical clock synchronization as guarantees.

Built on top of and integrated with Observables Extended, a Reactive Extensions inspired library for Elixir (https://github.com/DriesDeBackker/observables-extended).

Can be extended with new guarantees if so desired by adding an implementation for the necessary operations in the Context module. See the original 'Quality Aware Reactive Programming for the IoT' paper by Proença, Baquera for further insights (https://haslab.uminho.pt/joseproenca/files/quarp.pdf). (N.B.: terminology and mechanism not strictly identical.)

This library was developed mainly for academic purposes, namely for exploring distributed reactive programming (for the IoT) with consistency guarantees.

## Installation

If [available in Hex](https://hex.pm/docs/publish), the package can be installed
by adding `quarp` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:quarp, "~> 1.1.0"}
  ]
end
```