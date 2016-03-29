defmodule Dag.JobQueue.Worker do
  @moduledoc """
  Interfaces with a Queue to perform the scheduled work
  """

  defstruct task: nil, args: [], state: :pending

  alias Dag.JobQueue.Server

  def process(queue, []), do: :done
  def process(queue, jobs) do
    jobs
    |> run
    |> case do
      :error ->
        retry queue
      :ok ->
        process queue, Server.next_for(queue)
    end

  end

  def run(jobs) do

  end

  def retry(queue) do

  end
end
