defmodule AssemblyLine.Worker do
  @moduledoc """
  The Worker module defines the behavior for any external Worker Module.
  """

  alias AssemblyLine.Job

  @callback perform(Job.t) :: any
end
