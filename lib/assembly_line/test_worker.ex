defmodule AssemblyLine.TestWorker do
  alias AssemblyLine.Job

  def perform(%Job{task: :e}), do: :timer.sleep(200)
  def perform(%Job{task: :c}), do: exit(:normal)
  def perform(job) do
    job
  end
end
