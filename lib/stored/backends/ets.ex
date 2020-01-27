defmodule Stored.Backends.ETS do
  @behaviour Stored.Backend

  def create(table_name) do
    :ets.new(table_name, [:set, :protected, :named_table])
    :ok
  end

  def put(item, table_name) do
    key = Stored.Item.key(item)
    record = {key, item}
    true = :ets.insert(table_name, record)
    {:ok, record}
  end

  def find(key, table_name) do
    table_name
    |> :ets.lookup(key)
    |> case do
      [{_, record} | _] ->
        {:ok, record}

      [] ->
        {:error, :not_found}
    end
  end

  def all(table_name) do
    table_name
    |> :ets.select([{{:_, :_}, [], [:"$_"]}])
    |> Enum.map(fn {_, item} -> item end)
  end
end
