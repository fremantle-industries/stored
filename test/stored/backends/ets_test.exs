defmodule Stored.Backends.ETSTest do
  use ExUnit.Case, async: true

  @test_store_id __MODULE__
  @mj %TestSupport.Person{first_name: "Michael", last_name: "Jordan"}

  defmodule TestStore do
    use Stored.Store, backend: Stored.Backends.ETS
  end

  defmodule TestSlowReadStore do
    use Stored.Store, backend: Stored.Backends.SlowReadETS
  end

  setup do
    start_supervised({TestStore, id: @test_store_id})
    start_supervised({TestSlowReadStore, id: @test_store_id})
    :ok
  end

  describe ".put/1" do
    test "can inject a record into the backend" do
      process_name = TestStore.process_name(@test_store_id)

      assert {:ok, _} = TestStore.put(@mj, @test_store_id)

      records = :ets.lookup(process_name, "Michael_Jordan")
      assert Enum.count(records) == 1
      assert Enum.at(records, 0) == {"Michael_Jordan", @mj}
    end

    test "returns the key & record" do
      start_supervised({TestStore, id: @test_store_id})

      assert {:ok, {u_mj_key, u_mj}} = TestStore.put(@mj, @test_store_id)
      assert u_mj_key == "Michael_Jordan"
      assert u_mj == @mj
    end
  end

  test "can find a record by key" do
    TestStore.put(@mj, @test_store_id)

    assert {:ok, found_record} = TestStore.find("Michael_Jordan", @test_store_id)
    assert found_record == @mj

    assert TestStore.find("Lebron_James", @test_store_id) == {:error, :not_found}
  end

  test "can get all records" do
    assert TestStore.all(@test_store_id) == []

    assert {:ok, _} = TestStore.put(@mj, @test_store_id)

    records = TestStore.all(@test_store_id)
    assert Enum.count(records) == 1
    assert Enum.at(records, 0) == @mj
  end

  test "can find a record by key [on the client side]" do
    TestSlowReadStore.put(@mj, @test_store_id)
    results = List.duplicate({:ok, @mj}, 5)

    assert {run_time_a, ^results} =
      :timer.tc(fn ->
        1..5
        |> Enum.map(fn _ ->
          Task.async(fn -> TestSlowReadStore.find("Michael_Jordan", @test_store_id) end)
        end)
        |> Enum.map(&Task.await/1)
      end)

    assert {run_time_b, ^results} =
      :timer.tc(fn ->
        1..5
        |> Enum.map(fn _ ->
          Task.async(fn -> TestSlowReadStore.client_find("Michael_Jordan", @test_store_id) end)
        end)
        |> Enum.map(&Task.await/1)
      end)

    assert run_time_a > run_time_b
    assert ceil(run_time_a / run_time_b) >= 5
  end

  test "can get all records [on the client side]" do
    assert TestSlowReadStore.all(@test_store_id) == []
    TestSlowReadStore.put(@mj, @test_store_id)
    records = TestSlowReadStore.all(@test_store_id)
    results = List.duplicate(records, 5)

    assert {run_time_a, ^results} =
      :timer.tc(fn ->
        1..5
        |> Enum.map(fn _ ->
          Task.async(fn -> TestSlowReadStore.all(@test_store_id) end)
        end)
        |> Enum.map(&Task.await/1)
      end)

    assert {run_time_b, ^results} =
      :timer.tc(fn ->
        1..5
        |> Enum.map(fn _ ->
          Task.async(fn -> TestSlowReadStore.client_all(@test_store_id) end)
        end)
        |> Enum.map(&Task.await/1)
      end)

    assert run_time_a > run_time_b
    assert ceil(run_time_a / run_time_b) >= 5
  end

  describe ".delete/1" do
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

  test ".count returns the number of records in the store" do
    assert TestStore.count(@test_store_id) == 0

    assert {:ok, _} = TestStore.put(@mj, @test_store_id)
    assert TestStore.count(@test_store_id) == 1
  end

  test ".client_count returns the number of records in the store [on the client side]" do
    assert TestSlowReadStore.client_count(@test_store_id) == 0

    assert {:ok, _} = TestSlowReadStore.put(@mj, @test_store_id)
    assert TestSlowReadStore.client_count(@test_store_id) == 1
  end

  test "can clear all records" do
    assert TestStore.all(@test_store_id) == []
    assert {:ok, _} = TestStore.put(@mj, @test_store_id)

    records = TestStore.all(@test_store_id)
    assert Enum.count(records) == 1

    assert TestStore.clear(@test_store_id) == :ok
    records = TestStore.all(@test_store_id)
    assert Enum.count(records) == 0
  end
end
