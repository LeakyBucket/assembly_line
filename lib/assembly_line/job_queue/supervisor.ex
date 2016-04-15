defmodule AssemblyLine.JobQueue.Supervisor do
  use Supervisor
  alias AssemblyLine.JobQueue.Server

  def start_link do
    Supervisor.start_link(__MODULE__, [], name: __MODULE__)
  end

  def init(_) do
    children = [
      worker(Server, [], restart: :temporary)
    ]

    supervise(children, strategy: :simple_one_for_one)
  end

  def start_queue(name, work) do
    Supervisor.start_child(__MODULE__, [name, work])
  end

  def stop_queue(name) do
    Server.finished(name)
  end
end
