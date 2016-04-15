defmodule AssemblyLine do
  use Application

  def start(_type, _args) do
    import Supervisor.Spec, warn: false

    children = [
      supervisor(AssemblyLine.JobQueue.Supervisor, [], restart: :permanent)
    ]

    supervise(children, strategy: :one_for_one)
  end
end
