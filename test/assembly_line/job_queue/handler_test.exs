defmodule AssemblyLine.JobQueue.HandlerTest do
  defmodule CustomWorker do
    alias AssemblyLine.Job

    @behaviour AssemblyLine.Worker

    def perform(%Job{task: :c} = _job), do: exit(:normal)
    def perform(%Job{task: :e} = _job), do: :timer.sleep(250)
    def perform(%Job{} = _job) do
      :custom_worker_finished
    end
  end

  use ExUnit.Case
  alias AssemblyLine.JobQueue.Handler
  alias AssemblyLine.JobQueue.Server
  alias AssemblyLine.Job

  @bad_set_server "bad_set"
  @happy_server "happy"
  @bad_individual_server "bad_seed"
  @nested_name "nested"
  @inner_name "inner"

  setup do
    a = %Job{task: :a, worker: CustomWorker}
    b = %Job{task: :b, worker: CustomWorker}
    c = %Job{task: :c, worker: CustomWorker}
    d = %Job{task: :d, worker: CustomWorker}
    e = %Job{task: :e, worker: CustomWorker}
    f = %Job{task: :f, worker: CustomWorker}

    {:ok, error_server} = Server.start_link(@bad_set_server, [[a, b], [c, d], e])
    {:ok, good_server} = Server.start_link(@happy_server, [[a, b], [d, e], f])
    {:ok, single_bad} = Server.start_link(@bad_individual_server, [[a, b], c, [d, e]])
    {:ok, _inner} = Server.start_link(@inner_name, [a, b])
    {:ok, _outer} = Server.start_link(@nested_name, [[d, e, "inner"], f])
    {:ok, error_server: error_server, happy_server: good_server, single_bad: single_bad, a: a, b: b, c: c, e: e, d: d}
  end

  test "running a successful set" do
    assert {:incomplete, []} = Handler.process_set(@happy_server, Server.next_set(@happy_server))
  end

  test "running an unsuccessful set", %{c: c} do
    expected = Job.register_queue(c, @bad_set_server)

    assert {:incomplete, [^expected]} = Handler.start_all(@bad_set_server)
  end

  test "running a slow set", %{d: d, e: e} do
    Server.complete_current_set(@happy_server)
    work = [Job.register_queue(d, @happy_server), Job.register_queue(e, @happy_server)]

    assert {:incomplete, []} = Handler.process_set(@happy_server, work)
  end

  test "running a single failing task", %{c: c} do
    expected = Job.register_queue(c, @bad_individual_server)

    assert {:incomplete, [^expected]} = Handler.start_all(@bad_individual_server)
  end

  test "running a full queue without error" do
    assert :finished = Handler.start_all @happy_server
  end

  test "running a full queue with errors", %{c: c} do
    expected = Job.register_queue(c, @bad_set_server)

    assert {:incomplete, [^expected]} = Handler.start_all @bad_set_server
  end

  @tag :custom_worker
  test "It uses the specified worker" do
    job = %Job{task: :a, worker: CustomWorker, queue: "custom worker", args: []}

    {:ok, _queue} = Server.start_link "custom worker", [job]
    assert {:incomplete, []} = Handler.process_set "custom worker", [job]
  end

  test "it uses the default worker" do
    a = %Job{task: :a, args: []}
    {:ok, _queue} = AssemblyLine.JobQueue.Server.start_link("default worker", [a])

    assert :finished = Handler.start_all "default worker"
  end

  test "processing a nested queue" do
    assert :finished = Handler.start_all @nested_name
  end
end
