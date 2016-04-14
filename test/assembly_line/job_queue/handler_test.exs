defmodule AssemblyLine.JobQueue.HandlerTest do
  use ExUnit.Case
  alias AssemblyLine.JobQueue.Handler
  alias AssemblyLine.JobQueue.Server
  alias AssemblyLine.Job

  @bad_set_server "bad_set"
  @happy_server "happy"
  @bad_individual_server "bad_seed"

  setup do
    a = %Job{task: :a}
    b = %Job{task: :b}
    c = %Job{task: :c}
    d = %Job{task: :d}
    e = %Job{task: :e}
    f = %Job{task: :f}

    {:ok, error_server} = Server.start_link(@bad_set_server, [[a, b], [c, d], e])
    {:ok, good_server} = Server.start_link(@happy_server, [[a, b], [d, e], f])
    {:ok, single_bad} = Server.start_link(@bad_individual_server, [[a, b], c, [d, e]])
    {:ok, error_server: error_server, happy_server: good_server, single_bad: single_bad, a: a, b: b, c: c, e: e, d: d}
  end

  test "running a successful set", %{a: a, b: b} do
    assert {:incomplete, []} = Handler.process_set(@happy_server, [a, b])
  end

  test "running an unsuccessful set", %{c: c, d: d} do
    Server.complete_current_set(@bad_set_server)

    assert {:incomplete, [^c]} = Handler.process_set(@bad_set_server, [c, d])
  end

  test "running a slow set", %{d: d, e: e} do
    Server.complete_current_set(@happy_server)

    assert {:incomplete, []} = Handler.process_set(@happy_server, [d, e])
  end

  test "running a single failing task", %{c: c} do
    Server.complete_current_set(@bad_individual_server)

    assert {:incomplete, [^c]} = Handler.process_set(@bad_individual_server, [c])
  end

  test "running a full queue without error" do
    assert :finished = Handler.start_all @happy_server
  end

  test "running a full queue with errors", %{c: c} do
    assert {:incomplete, [^c]} = Handler.start_all @bad_set_server
  end
end
