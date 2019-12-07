defmodule Stored.Store do
  @callback backend_created() :: no_return
  @optional_callbacks backend_created: 0

  defmacro __using__(_) do
    quote location: :keep do
      use GenServer

      @behaviour Stored.Store

      @type store_id :: atom
      @type record :: Stored.Backend.record()
      @type key :: Stored.Backend.key()

      @default_id :default
      @default_backend Stored.Backends.ETS

      defmodule State do
        @type t :: %State{id: atom, name: atom, backend: module}
        defstruct ~w(id name backend)a
      end

      def start_link(args) do
        id = Keyword.get(args, :id, @default_id)
        backend = Keyword.get(args, :backend, @default_backend)
        name = to_name(id)
        state = %State{id: id, name: name, backend: backend}

        GenServer.start_link(__MODULE__, state, name: name)
      end

      @spec to_name(store_id) :: atom
      def to_name(store_id), do: :"#{__MODULE__}_#{store_id}"

      def upsert(item, store_id \\ @default_id) do
        store_id
        |> to_name
        |> GenServer.call({:upsert, item})
      end

      @spec find(key) :: {:ok, record} | {:error, :not_found}
      def find(key, store_id \\ @default_id) do
        store_id
        |> to_name
        |> GenServer.call({:find, key})
      end

      def all(store_id \\ @default_id) do
        store_id
        |> to_name
        |> GenServer.call(:all)
      end

      def init(state), do: {:ok, state, {:continue, :init}}

      def handle_continue(:init, state) do
        :ok = state.backend.create(state.name)
        backend_created()
        {:noreply, state}
      end

      def handle_call({:upsert, item}, _from, state) do
        response = state.backend.upsert(item, state.name)
        {:reply, response, state}
      end

      def handle_call({:find, key}, _from, state) do
        response = state.backend.find(key, state.name)
        {:reply, response, state}
      end

      def handle_call(:all, _from, state) do
        response = state.backend.all(state.name)
        {:reply, response, state}
      end

      def backend_created, do: nil

      defoverridable backend_created: 0
    end
  end
end
