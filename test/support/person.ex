defmodule TestSupport.Person do
  defstruct ~w(first_name last_name)a
end

defimpl Stored.Item, for: TestSupport.Person do
  def key(p), do: "#{p.first_name}_#{p.last_name}"
end
