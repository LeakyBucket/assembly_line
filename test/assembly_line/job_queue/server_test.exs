defmodule AssemblyLine.JobQueue.ServerTest do
  use ExUnit.Case

  alias AssemblyLine.JobQueue.Server

  @name :test

  setup do
    {:ok, agent} = Server.start_link(@name, [[:a, :b], :c])
    {:ok, agent: agent}
  end

  test "fetching the next task" do
    assert [:a, :b] = Server.next_for @name
  end

  test "completing the current task set" do
    Server.complete_current_set :test
    expected = MapSet.new([:a, :b])

    assert ^expected = Server.get_completed :test
  end

  test "getting completed tasks" do
    assert %MapSet{} = Server.get_completed :test
  end

  test "completing a single task" do
    Server.complete_job :test, :a
    expected = MapSet.new([:a])

    assert ^expected = Server.get_completed :test
  end
end
