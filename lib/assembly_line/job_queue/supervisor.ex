defmodule AssemblyLine.JobQueue.Supervisor do
  @moduledoc """
  Provides supervision of the `AssemblyLine.JobQueue.Server` services as well as
  functions for starting and stopping new instances.

  The Supervisor is started at the same time the application is started.
  """

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

  @doc """
  Starts a new `AssemblyLine.JobQueue.Server` with the given `name` and `work`
  list.

  Returns `{:ok, pid}`
  """
  @spec start_queue(String.t, list(AssemblyLine.Job.t)) :: {:ok, pid}
  def start_queue(name, work) do
    Supervisor.start_child(__MODULE__, [name, work])
  end

  @doc """
  Stops the `AssemblyLine.JobQueue.Server` with the specified `name`.

  Returns `:ok`
  """
  @spec stop_queue(String.t) :: :ok
  def stop_queue(name) do
    Server.finished(name)
  end
end
