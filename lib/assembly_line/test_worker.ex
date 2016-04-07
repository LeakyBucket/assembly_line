defmodule AssemblyLine.TestWorker do
  alias AssemblyLine.Job

  def perform(%Job{task: :c}), do: exit(:normal)
  def perform(job) do
    job
  end
end
