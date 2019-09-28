defmodule Stored.StoreTest do
  use ExUnit.Case, async: true

  @test_store_id __MODULE__

  defmodule TestStore do
    use Stored.Store
  end

  defmodule TestStoreWithCallbacks do
    use Stored.Store

    def backend_created do
      send(Stored.StoreTest, :backend_created)
    end
  end

  test "can start multiple stores" do
    assert {:ok, pid_a} = TestStore.start_link(id: :"#{@test_store_id}_a")
    assert {:ok, pid_b} = TestStore.start_link(id: :"#{@test_store_id}_b")
    assert :ok = GenServer.stop(pid_a)
    assert :ok = GenServer.stop(pid_b)
  end

  test "fires the backend_created callback" do
    Process.register(self(), __MODULE__)

    start_supervised!({TestStoreWithCallbacks, id: @test_store_id})

    assert_receive :backend_created
  end

  test "can upsert an item" do
    lebron = %TestSupport.Person{first_name: "Lebron", last_name: "James"}
    mj = %TestSupport.Person{first_name: "Michael", last_name: "Jordan"}
    start_supervised({TestStore, id: @test_store_id})

    assert {:ok, {u_lebron_key, u_lebron}} = TestStore.upsert(lebron, @test_store_id)
    assert u_lebron_key == "Lebron_James"
    assert u_lebron == lebron

    assert {:ok, {u_mj_key, u_mj}} = TestStore.upsert(mj, @test_store_id)
    assert u_mj_key == "Michael_Jordan"
    assert u_mj == mj
  end

  test "can get all items" do
    mj = %TestSupport.Person{first_name: "Michael", last_name: "Jordan"}
    start_supervised({TestStore, id: @test_store_id})

    assert TestStore.all(@test_store_id) == []

    assert {:ok, _} = TestStore.upsert(mj, @test_store_id)

    assert [u_mj | []] = TestStore.all(@test_store_id)
    assert u_mj == mj
  end
end
