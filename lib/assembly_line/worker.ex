defmodule AssemblyLine.Worker do
  alias AssemblyLine.Job

  @callback perform(Job.t) :: any
end
