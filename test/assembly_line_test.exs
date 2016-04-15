defmodule AssemblyLineTest do
  use ExUnit.Case
  alias AssemblyLine.JobQueue.Supervisor

  setup do
    {:ok, app} = AssemblyLine.start(:normal, [])
    {:ok, application: app}
  end

  test "application starts", %{application: app} do
    assert is_pid(app)
  end

  test "application starts an AssemblyLine.JobQueue.Supervisor" do
    assert {:ok, _} = Supervisor.start_queue("bob", [])
  end
end
