defmodule AssemblyLine.JobQueue.SupervisorTest do
  use ExUnit.Case
  alias AssemblyLine.JobQueue.Supervisor
  alias AssemblyLine.Job

  @queue_name "sup_test"
  @job_a %Job{task: :a, args: []}

  setup do
    {:ok, supervisor} = Supervisor.start_link
    {:ok, sup: supervisor}
  end

  test "starting a new job queue" do
    {:ok, server} = Supervisor.start_queue @queue_name, [@job_a]

    assert is_pid(server)
  end

  test "stopping a job queue" do
    {:ok, _} = Supervisor.start_queue @queue_name, [@job_a]

    assert :ok = Supervisor.stop_queue @queue_name
  end
end
