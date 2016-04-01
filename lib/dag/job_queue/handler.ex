defmodule Dag.JobQueue.Handler do
  @moduledoc """
  Responsible for passing jobs from the queue to whatever the backend
  responsible for processing them.
  """

  alias Dag.JobQueue.Server

  @executor Application.get_env(:dag, :job_executor)
  @check_interval Application.get_env(:dag, :check_interval) || 1000

  @doc """
  Starts job processing for the `name` Queue
  """
  def start_processing(name) do
    process name, Server.next_for(name)
  end

  defp process(name, []), do: :finished
  defp process(name, jobs) do
    jobs
    |> run_set
    |> case do

    end
  end

  # Need to tie the task to the job for tracking purposes
  defp run_set(jobs) do
    tasks = Enum.map(jobs, fn job ->
      Task.async @executor, :perform, [job]
    end)

    await_tasks [tasks, []]
  end

  defp await_tasks([[] | finished]), do: {:finished, finished}
  defp await_tasks([outstanding | finished]) do
    [running | newly_finished] = outstanding
    |> Task.yield_many(@check_interval)
    |> filter_by_status

    await_tasks [running, newly_finished ++ finished]
  end

  def filter_by_status(yield_results) do
    Enum.reduce(yield_results, [[], []], fn [outstanding, finished], status ->
      case status do
        {_task, {:ok, response}} ->
          [outstanding, [{:ok, response}] ++ finished]
        {_task, {:error, reason}} ->
          [outstanding, [{:error, reason}] ++ finished]
        {task, nil} ->
          [[task] ++ outstanding, finished]
      end
    end)
  end
end
