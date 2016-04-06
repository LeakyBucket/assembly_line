defmodule AssemblyLine.JobQueue.Handler do
  @moduledoc """
  Responsible for passing jobs from the queue to whatever the backend
  responsible for processing them.
  """

  alias AssemblyLine.JobQueue.Server

  @executor Application.get_env(:assembly_line, :job_executor)
  @check_interval Application.get_env(:assembly_line, :check_interval) || 1000

  @doc """
  Starts job processing for the `queue`.

  Returns `:finished` or `:incomplete`.
  """
  def start_all(queue) do
    queue
    |> process(Server.next_for queue)
  end

  @doc """
  Processes the specified `queue`

  Returns `:finished` if the entire pipeline completes successfuly.  Otherwise
  it returns `{:incomplete, [%AssemblyLine.Job{}]}` where the second part of
  the tuple is a list of `AssemblyLine.JobQueue.Job` structs which failed to
  process.
  """
  def process(_queue, []), do: :finished
  def process(queue, _jobs) do
    queue
    |> process_set(Server.next_for(queue))
    |> case do
      {:incomplete, []} ->
        process(queue, Server.next_for(queue))
      {:incomplete, failed} ->
        {:incomplete, failed}
    end
  end

  @doc """
  Processes a set of jobs asynchronously and monitors their status.

  Returns `{:incomplete, [] | [%AssemblyLine.Job{}]}` where the second tuple
  element is a list of jobs that failed.
  """
  def process_set(queue, jobs) do
    jobs
    |> start_jobs
    |> monitor(queue)
  end

  defp start_jobs(jobs) do
    Enum.reduce(jobs, %{}, fn job, acc ->
      Map.put acc, Task.async(@executor, :perform, [job]), job
    end)
  end

  defp monitor(task_map, queue) when map_size(task_map) == 0, do: {:incomplete, Server.next_for(queue)}
  defp monitor(task_map, queue) do
    task_map
    |> Map.keys
    |> Task.yield_many(@check_interval)
    |> process_results(task_map, queue)
    |> monitor(queue)
  end

  defp process_results(task_list, task_map, queue) do
    task_list
    |> Enum.reduce(task_map, fn task, map ->
      update_task_map(task, map, queue)
    end)
  end

  defp update_task_map(nil, task_map, _queue), do: task_map
  defp update_task_map({t, {:ok, _response}}, task_map, queue) do
    task_map
    |> Map.get(t)
    |> Server.complete_job(queue)

    task_map
    |> Map.delete(t)
  end
  defp update_task_map({t, {:exit, _reason}}, task_map, _queue) do
    task_map
    |> Map.delete(t)
  end
end