defmodule AssemblyLine.Job do
  defstruct task: nil, args: [], result: nil

  def set_result(job, result) do
    struct job, result: result
  end
end
