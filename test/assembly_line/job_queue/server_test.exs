defmodule AssemblyLine.JobQueue.ServerTest do
  use ExUnit.Case

  alias AssemblyLine.JobQueue.Server
  alias AssemblyLine.Job

  @name "test_server"
  @nested_name "outer"
  @inner_name "inner"

  setup do
    a = %Job{task: :a}
    b = %Job{task: :b}
    c = %Job{task: :c}
    d = %Job{task: :d}

    {:ok, agent} = Server.start_link(@name, [[a, b], c])
    {:ok, inner} = Server.start_link(@inner_name, [a, b])
    {:ok, outer} = Server.start_link(@nested_name, [[c, @inner_name], d])

    {:ok, agent: agent, inner: inner, nested: outer, a: a, b: b, c: c, d: d}
  end

  test "fetching the next task" do
    assert [%Job{task: :a}, %Job{task: :b}] = Server.next_set @name
  end

  test "getting next task when empty" do
    Server.complete_current_set @name
    Server.complete_current_set @name

    assert [] = Server.next_set @name
  end

  test "completing the current task set" do
    Server.complete_current_set @name
    expected =MapSet.new([%Job{task: :a, queue: @name}, %Job{task: :b, queue: @name}])

    assert ^expected = Server.get_completed @name
  end

  test "completing the current set when it is a singleton" do
    Server.complete_current_set @name
    Server.complete_current_set @name

    expected = MapSet.new([
      %Job{task: :a, queue: @name},
      %Job{task: :b, queue: @name},
      %Job{task: :c, queue: @name}
    ])

    assert ^expected = Server.get_completed @name
  end

  test "getting completed tasks" do
    assert %MapSet{} = Server.get_completed @name
  end

  test "completing a single task from a set", %{a: a} do
    Server.finish_job a, @name, :ok
    expected = MapSet.new([Job.set_result(a, :ok)])

    assert ^expected = Server.get_completed @name
  end

  test "completing a singleton task" do
    Server.complete_current_set @name
    Server.finish_job %Job{task: :c, queue: @name}, @name, :ok

    expected = MapSet.new([
      %Job{task: :a, queue: @name},
      %Job{task: :b, queue: @name},
      %Job{task: :c, queue: @name, result: :ok}
    ])

    assert ^expected = Server.get_completed @name
  end

  test "shutting down", %{agent: agent} do
    Server.finished @name

    refute Process.alive? agent
  end

  test "queue tracking" do
    [a, _b] = Server.next_set(@name)

    assert @name = a.queue
  end

  test "getting the next job with a nested queue" do
    [a, b] = Server.next_set(@nested_name)

    assert @nested_name = a.queue
    assert @inner_name = b.queue
  end

  test "completing a job for a nested queue" do
    [_c, a] = Server.next_set(@nested_name)
    Server.finish_job(a, @nested_name, :ok)
    expected = MapSet.new([Job.set_result(a, :ok)])

    assert ^expected = Server.get_completed(@nested_name)
    assert ^expected = Server.get_completed(@inner_name)
  end

  test "completing all jobs for a nested queue" do
    [_c, a] = Server.next_set(@nested_name)
    Server.finish_job(a, @nested_name, :ok)
    [c, b] = Server.next_set(@nested_name)
    Server.finish_job(b, @nested_name, :ok)

    assert a != b
    assert [^c] = Server.next_set(@nested_name)
  end

  test "nested queues are stopped when completed", %{inner: inner} do
    [outer, inner_job] = Server.next_set(@nested_name)
    Server.finish_job(outer, @nested_name, :ok)
    Server.finish_job(inner_job, @nested_name, :ok)

    [inner_job] = Server.next_set(@nested_name)
    Server.finish_job(inner_job, @nested_name, :ok)

    :timer.sleep(5)
    refute Process.alive?(inner)
  end

  test "nested queue job processing order", %{a: a, b: b, c: c, d: d} do
    [outer, inner] = Server.next_set(@nested_name)
    assert ^outer = struct(c, queue: @nested_name)
    assert ^inner = struct(a, queue: @inner_name)

    Server.finish_job(inner, @nested_name, :ok)

    [outer, inner] = Server.next_set(@nested_name)
    assert ^outer = struct(c, queue: @nested_name)
    assert ^inner = struct(b, queue: @inner_name)

    Server.finish_job(outer, @nested_name, :ok)

    [inner] = Server.next_set(@nested_name)
    assert ^inner = struct(b, queue: @inner_name)

    Server.finish_job(inner, @nested_name, :ok)

    [outer_end] = Server.next_set(@nested_name)
    assert ^outer_end = struct(d, queue: @nested_name)
  end
end
