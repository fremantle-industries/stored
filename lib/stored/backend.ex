defmodule Stored.Backend do
  @type table_name :: atom
  @type key :: term

  @callback create(table_name) :: :ok
  @callback upsert(struct, table_name) :: {:ok, {key, struct}}
  @callback all(table_name) :: [struct]
end
