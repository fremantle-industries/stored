# Stored

[![Build Status](https://github.com/rupurt/stored/workflows/test/badge.svg?branch=main)](https://github.com/rupurt/stored/actions?query=workflow%3Atest)
[![hex.pm version](https://img.shields.io/hexpm/v/stored.svg?style=flat)](https://hex.pm/packages/stored)

Store & retrieve structs against various backends with a simple lightweight API.

By default `stored` ships with an ETS backend. Custom backends can be added by implementing the `Stored.Backend` behaviour.

## Installation

```elixir
def deps do
  [
    {:stored, "~> 0.0.8"}
  ]
end
```

## Usage

```elixir
defmodule Person do
  defstruct ~w(first_name last_name)a
end

defimpl Stored.Item, for: Person do
  def key(p), do: "#{p.first_name}_#{p.last_name}"
end

defmodule MyStore do
  use Stored.Store

  def after_backend_create, do: nil
  def after_put(_record), do: nil
end

{:ok, pid_default} = MyStore.start_link()
{:ok, pid_a} = MyStore.start_link(id: :a)

lebron = %Person{first_name: "Lebron", last_name: "James"}

{:ok, {r_lebron_key_default, r_lebron_default}} = MyStore.put(lebron)
{:ok, {r_lebron_key_a, r_lebron_a}} = MyStore.put(lebron, :a)

people_default = MyStore.all()
people_a = MyStore.all(:a)
```
