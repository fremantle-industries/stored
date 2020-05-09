defmodule Stored.StoreTest do
  use ExUnit.Case, async: true

  @test_store_id __MODULE__

  defmodule TestStore do
    use Stored.Store

    def after_backend_create do
      send(Stored.StoreTest, :after_backend_create)
    end

    def after_put(record) do
      send(Stored.StoreTest, {:after_put, record})
    end

    def after_delete(record) do
      send(Stored.StoreTest, {:after_delete, record})
    end

    def after_clear do
      send(Stored.StoreTest, :after_clear)
    end
  end

  setup do
    Process.register(self(), @test_store_id)
    :ok
  end

  test "can start multiple stores" do
    assert {:ok, pid_a} = TestStore.start_link(id: :"#{@test_store_id}_a")
    assert {:ok, pid_b} = TestStore.start_link(id: :"#{@test_store_id}_b")
    assert :ok = GenServer.stop(pid_a)
    assert :ok = GenServer.stop(pid_b)
  end

  test "fires callback 'after_backend_create/0'" do
    start_supervised!({TestStore, id: @test_store_id})

    assert_receive :after_backend_create
  end

  test ".put/1 fires callback 'after_put/1'" do
    start_supervised!({TestStore, id: @test_store_id})

    lebron = %TestSupport.Person{first_name: "Lebron", last_name: "James"}

    assert {:ok, {u_lebron_key, u_lebron}} = TestStore.put(lebron, @test_store_id)
    assert_receive {:after_put, put_record}
  end

  test ".delete/1 fires callback 'after_delete/1'" do
    start_supervised!({TestStore, id: @test_store_id})

    lebron = %TestSupport.Person{first_name: "Lebron", last_name: "James"}

    assert {:ok, _} = TestStore.put(lebron, @test_store_id)
    assert_receive {:after_put, _}

    assert {:ok, _} = TestStore.delete(lebron, @test_store_id)
    assert_receive {:after_delete, deleted_key}
    assert deleted_key == "Lebron_James"
  end

  test ".clear/0 fires callback 'after_clear/0'" do
    start_supervised!({TestStore, id: @test_store_id})

    assert TestStore.clear(@test_store_id) == :ok
    assert_receive :after_clear
  end
end
