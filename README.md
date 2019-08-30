# Stored
[![CircleCI](https://circleci.com/gh/rupurt/stored.svg?style=svg)](https://circleci.com/gh/rupurt/stored)

Store & query structs against various backends with a simple lightweight API.

By default `stored` ships with an ETS backend. Custom backends can be added by implementing the `Stored.Backend` behaviour.

## Installation

```elixir
def deps do
  [
    {:stored, "~> 0.0.1"}
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
end

{:ok, pid_default} = MyStore.start_link()
{:ok, pid_a} = MyStore.start_link(id: :a)

lebron = %Person{first_name: "Lebron", last_name: "James"}

{:ok, {u_lebron_key_default, u_lebron_default}} = MyStore.upsert(lebron)
{:ok, {u_lebron_key_a, u_lebron_a}} = MyStore.upsert(lebron, :a)

people_default = MyStore.all()
people_a = MyStore.all(:a)
```
