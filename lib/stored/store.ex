defmodule Stored.Store do
  @type record :: Stored.Backend.record()

  @callback backend_created() :: no_return
  @callback after_backend_create() :: no_return
  @callback after_put(record) :: no_return
  @callback after_delete(record) :: no_return
  @callback after_clear() :: no_return
  @optional_callbacks after_backend_create: 0,
                      backend_created: 0,
                      after_put: 1,
                      after_delete: 1,
                      after_clear: 0

  defmacro __using__(opts \\ []) do
    quote bind_quoted: [opts: opts], location: :keep do
      use GenServer

      @behaviour Stored.Store

      @type store_id :: atom
      @type record :: Stored.Backend.record()
      @type key :: Stored.Backend.key()

      @default_id :default
      @backend Keyword.get(opts, :backend, Stored.Backends.ETS)

      defmodule State do
        @type t :: %State{id: atom, name: atom}
        defstruct ~w(id name)a
      end

      def start_link(args) do
        id = Keyword.get(args, :id, @default_id)
        name = process_name(id)
        state = %State{id: id, name: name}

        GenServer.start_link(__MODULE__, state, name: name)
      end

      @spec process_name(store_id) :: atom
      def process_name(store_id), do: :"#{__MODULE__}_#{store_id}"

      @since "0.0.6"
      @deprecated "Use Stored.Store.process_name/1 instead"
      @spec to_name(store_id) :: atom
      def to_name(store_id), do: process_name(store_id)

      @spec put(record) :: {:ok, {key, record}}
      def put(record, store_id \\ @default_id) do
        store_id
        |> process_name
        |> GenServer.call({:put, record})
      end

      @spec find(key) :: {:ok, record} | {:error, :not_found}
      def find(key, store_id \\ @default_id) do
        store_id
        |> process_name
        |> GenServer.call({:find, key})
      end

      @spec all :: [record]
      def all(store_id \\ @default_id) do
        store_id
        |> process_name
        |> GenServer.call(:all)
      end

      @spec delete(record | term) :: {:ok, key}
      def delete(record_or_key, store_id \\ @default_id) do
        store_id
        |> process_name
        |> GenServer.call({:delete, record_or_key})
      end

      @spec count :: non_neg_integer
      def count(store_id \\ @default_id) do
        store_id
        |> process_name
        |> GenServer.call(:count)
      end

      @spec clear :: :ok
      def clear(store_id \\ @default_id) do
        store_id
        |> process_name
        |> GenServer.call(:clear)
      end

      def init(state), do: {:ok, state, {:continue, :init}}

      def handle_continue(:init, state) do
        :ok = @backend.create(state.name)
        after_backend_create()
        backend_created()
        {:noreply, state}
      end

      def handle_call({:put, record}, _from, state) do
        response = @backend.put(record, state.name)
        after_put(record)
        {:reply, response, state}
      end

      def handle_call({:find, key}, _from, state) do
        response = @backend.find(key, state.name)
        {:reply, response, state}
      end

      def handle_call(:all, _from, state) do
        response = @backend.all(state.name)
        {:reply, response, state}
      end

      def handle_call({:delete, record_or_key}, _from, state) do
        {:ok, key} = response = delete_by_record_or_key(record_or_key, state.name)
        after_delete(key)
        {:reply, response, state}
      end

      def handle_call(:count, _from, state) do
        response = @backend.count(state.name)
        {:reply, response, state}
      end

      def handle_call(:clear, _from, state) do
        response = @backend.clear(state.name)
        after_clear()
        {:reply, response, state}
      end

      def backend_created, do: nil
      def after_backend_create, do: nil
      def after_put(record), do: nil
      def after_delete(record), do: nil
      def after_clear, do: nil

      defoverridable after_backend_create: 0,
                     backend_created: 0,
                     after_put: 1,
                     after_delete: 1,
                     after_clear: 0

      defp delete_by_record_or_key(%_{} = record, name) do
        record
        |> Stored.Item.key()
        |> delete_by_record_or_key(name)
      end

      defp delete_by_record_or_key(key, name) do
        :ok = @backend.delete(key, name)
        {:ok, key}
      end
    end
  end
end
