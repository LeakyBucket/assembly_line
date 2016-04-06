defmodule AssemblyLine.TestWorker do
  def perform(:c), do: exit(:normal)
  def perform(job) do
    job
  end
end
