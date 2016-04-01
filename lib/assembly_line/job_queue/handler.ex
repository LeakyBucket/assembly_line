defmodule AssemblyLine.JobQueue.Handler do
  @moduledoc """
  Responsible for passing jobs from the queue to whatever the backend
  responsible for processing them.
  """

  alias AssemblyLine.JobQueue.Server

  @executor Application.get_env(:assembly_line, :job_executor)
  @check_interval Application.get_env(:assembly_line, :check_interval) || 1000

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
      {:finished, jobs} ->
        Server.complete_current
        process name, Server.next_for(name)
      {:incomplete, results} ->
        Enum.each(results[:done], fn job -> Server.complete_job(job) end)
        :incomplete
    end
  end

  # Need to tie the task to the job for tracking purposes
  defp run_set(jobs) do
    tasks = Enum.map(jobs, fn job ->
      Task.async @executor, :perform, [job]
    end)

    await_tasks [tasks, []]
  end

  defp await_tasks([[] | %{failed: [], done: done}]), do: {:finished, done}
  defp await_tasks([[] | %{failed: failed, done: done}]), do: {:incomplete, [failed: failed, done: done]}
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
