defmodule Stored.StoreTest do
  use ExUnit.Case, async: true

  @test_store_id __MODULE__

  defmodule TestStore do
    use Stored.Store
  end

  defmodule TestStoreWithCallbacks do
    use Stored.Store

    def after_backend_create do
      send(Stored.StoreTest, :after_backend_create)
    end
  end

  test "can start multiple stores" do
    assert {:ok, pid_a} = TestStore.start_link(id: :"#{@test_store_id}_a")
    assert {:ok, pid_b} = TestStore.start_link(id: :"#{@test_store_id}_b")
    assert :ok = GenServer.stop(pid_a)
    assert :ok = GenServer.stop(pid_b)
  end

  test "fires callback 'after_backend_create/0'" do
    Process.register(self(), __MODULE__)

    start_supervised!({TestStoreWithCallbacks, id: @test_store_id})

    assert_receive :after_backend_create
  end

  test "can put an item" do
    lebron = %TestSupport.Person{first_name: "Lebron", last_name: "James"}
    mj = %TestSupport.Person{first_name: "Michael", last_name: "Jordan"}
    start_supervised({TestStore, id: @test_store_id})

    assert {:ok, {u_lebron_key, u_lebron}} = TestStore.put(lebron, @test_store_id)
    assert u_lebron_key == "Lebron_James"
    assert u_lebron == lebron

    assert {:ok, {u_mj_key, u_mj}} = TestStore.put(mj, @test_store_id)
    assert u_mj_key == "Michael_Jordan"
    assert u_mj == mj
  end

  test "can find an item by key" do
    start_supervised({TestStore, id: @test_store_id})
    mj = %TestSupport.Person{first_name: "Michael", last_name: "Jordan"}
    TestStore.put(mj, @test_store_id)

    assert {:ok, found_record} = TestStore.find("Michael_Jordan", @test_store_id)
    assert found_record == mj

    assert TestStore.find("Lebron_James", @test_store_id) == {:error, :not_found}
  end

  test "can get all items" do
    start_supervised({TestStore, id: @test_store_id})

    assert TestStore.all(@test_store_id) == []

    mj = %TestSupport.Person{first_name: "Michael", last_name: "Jordan"}
    assert {:ok, _} = TestStore.put(mj, @test_store_id)

    assert [u_mj | []] = TestStore.all(@test_store_id)
    assert u_mj == mj
  end
end
