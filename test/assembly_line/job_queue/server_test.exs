defmodule AssemblyLine.JobQueue.ServerTest do
  use ExUnit.Case

  alias AssemblyLine.JobQueue.Server
  alias AssemblyLine.Job

  @name :server_test

  setup do
    a = %Job{task: :a}
    b = %Job{task: :b}
    c = %Job{task: :c}

    {:ok, agent} = Server.start_link(@name, [[a, b], c])
    {:ok, agent: agent, a: a, b: b, c: c}
  end

  test "fetching the next task", %{a: a, b: b} do
    assert [^a, ^b] = Server.next_for @name
  end

  test "getting next task when empty" do
    Server.complete_current_set @name
    Server.complete_current_set @name

    assert [] = Server.next_for @name
  end

  test "completing the current task set", %{a: a, b: b} do
    Server.complete_current_set @name
    expected = MapSet.new([a, b])

    assert ^expected = Server.get_completed @name
  end

  test "completing the current set when it is a singleton", %{a: a, b: b, c: c} do
    Server.complete_current_set @name
    Server.complete_current_set @name
    expected = MapSet.new([a, b, c])

    assert ^expected = Server.get_completed @name
  end

  test "getting completed tasks" do
    assert %MapSet{} = Server.get_completed @name
  end

  test "completing a single task from a set", %{a: a} do
    Server.complete_job a, @name
    expected = MapSet.new([a])

    assert ^expected = Server.get_completed @name
  end

  test "completing a singleton task", %{a: a, b: b, c: c} do
    Server.complete_current_set @name
    Server.complete_job c, @name
    expected = MapSet.new([a, b, c])

    assert ^expected = Server.get_completed @name
  end

  test "shutting down", %{agent: agent} do
    Server.finished @name

    refute Process.alive? agent
  end
end
