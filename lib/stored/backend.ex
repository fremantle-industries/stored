defmodule Stored.Backend do
  @type table_name :: atom
  @type record :: struct
  @type key :: term

  @callback create(table_name) :: :ok
  @callback put(struct, table_name) :: {:ok, {key, record}}
  @callback find(key, table_name) :: {:ok, record} | {:error, :not_found}
  @callback all(table_name) :: [struct]
end
