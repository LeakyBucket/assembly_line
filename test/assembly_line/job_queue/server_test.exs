defmodule AssemblyLine.JobQueue.ServerTest do
  use ExUnit.Case

  alias AssemblyLine.JobQueue.Server

  @name :server_test

  setup do
    {:ok, agent} = Server.start_link(@name, [[:a, :b], :c])
    {:ok, agent: agent}
  end

  test "fetching the next task" do
    assert [:a, :b] = Server.next_for @name
  end

  test "getting next task when empty" do
    Server.complete_current_set @name
    Server.complete_current_set @name

    assert [] = Server.next_for @name
  end

  test "completing the current task set" do
    Server.complete_current_set @name
    expected = MapSet.new([:a, :b])

    assert ^expected = Server.get_completed @name
  end

  test "completing the current set when it is a singleton" do
    Server.complete_current_set @name
    Server.complete_current_set @name
    expected = MapSet.new([:a, :b, :c])

    assert ^expected = Server.get_completed @name
  end

  test "getting completed tasks" do
    assert %MapSet{} = Server.get_completed @name
  end

  test "completing a single task from a set" do
    Server.complete_job :a, @name
    expected = MapSet.new([:a])

    assert ^expected = Server.get_completed @name
  end

  test "completing a singleton task" do
    Server.complete_current_set @name
    Server.complete_job :c, @name
    expected = MapSet.new([:a, :b, :c])

    assert ^expected = Server.get_completed @name
  end
end
