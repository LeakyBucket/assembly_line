defmodule AssemblyLine do
  @moduledoc """
  The AssemblyLine Module defines the application structure.
  """

  use Application
  alias AssemblyLine.JobQueue.Supervisor

  def start(_type, _args) do
    Supervisor.start_link
  end
end
