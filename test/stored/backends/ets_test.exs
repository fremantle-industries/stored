defmodule Stored.Backends.ETSTest do
  use ExUnit.Case, async: true

  @test_store_id __MODULE__

  defmodule TestStore do
    use Stored.Store, backend: Stored.Backends.ETS
  end

  setup do
    start_supervised({TestStore, id: @test_store_id})
    :ok
  end

  describe ".put/1" do
    test "can inject a record into the backend" do
      process_name = TestStore.process_name(@test_store_id)
      mj = %TestSupport.Person{first_name: "Michael", last_name: "Jordan"}

      assert {:ok, _} = TestStore.put(mj, @test_store_id)

      records = :ets.lookup(process_name, "Michael_Jordan")
      assert Enum.count(records) == 1
      assert Enum.at(records, 0) == {"Michael_Jordan", mj}
    end

    test "returns the key & record" do
      mj = %TestSupport.Person{first_name: "Michael", last_name: "Jordan"}
      start_supervised({TestStore, id: @test_store_id})

      assert {:ok, {u_mj_key, u_mj}} = TestStore.put(mj, @test_store_id)
      assert u_mj_key == "Michael_Jordan"
      assert u_mj == mj
    end
  end

  test "can find a record by key" do
    mj = %TestSupport.Person{first_name: "Michael", last_name: "Jordan"}
    TestStore.put(mj, @test_store_id)

    assert {:ok, found_record} = TestStore.find("Michael_Jordan", @test_store_id)
    assert found_record == mj

    assert TestStore.find("Lebron_James", @test_store_id) == {:error, :not_found}
  end

  test "can get all records" do
    assert TestStore.all(@test_store_id) == []

    mj = %TestSupport.Person{first_name: "Michael", last_name: "Jordan"}
    assert {:ok, _} = TestStore.put(mj, @test_store_id)

    records = TestStore.all(@test_store_id)
    assert Enum.count(records) == 1
    assert Enum.at(records, 0) == mj
  end

  describe ".delete/1" do
    @mj %TestSupport.Person{first_name: "Michael", last_name: "Jordan"}

    setup do
      TestStore.put(@mj, @test_store_id)

      assert {:ok, _} = TestStore.find("Michael_Jordan", @test_store_id)
      :ok
    end

    test "can delete by struct" do
      assert {:ok, "Michael_Jordan"} = TestStore.delete(@mj, @test_store_id)
      assert TestStore.find("Michael_Jordan", @test_store_id) == {:error, :not_found}
    end

    test "can delete by key" do
      assert {:ok, "Michael_Jordan"} = TestStore.delete("Michael_Jordan", @test_store_id)
      assert TestStore.find("Michael_Jordan", @test_store_id) == {:error, :not_found}
    end
  end

  test "can clear all records" do
    assert TestStore.all(@test_store_id) == []

    mj = %TestSupport.Person{first_name: "Michael", last_name: "Jordan"}
    assert {:ok, _} = TestStore.put(mj, @test_store_id)

    records = TestStore.all(@test_store_id)
    assert Enum.count(records) == 1

    assert TestStore.clear(@test_store_id) == :ok
    records = TestStore.all(@test_store_id)
    assert Enum.count(records) == 0
  end
end
