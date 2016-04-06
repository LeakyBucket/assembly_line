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

  test "completing the current task set" do
    Server.complete_current_set @name
    expected = MapSet.new([:a, :b])

    assert ^expected = Server.get_completed @name
  end

  test "getting completed tasks" do
    assert %MapSet{} = Server.get_completed @name
  end

  test "completing a single task" do
    Server.complete_job :a, @name
    expected = MapSet.new([:a])

    assert ^expected = Server.get_completed @name
  end

  #TODO: Need to test behavior when completing only job in a single job `set`
end
