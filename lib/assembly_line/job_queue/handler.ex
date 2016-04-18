defmodule AssemblyLine.JobQueue.Handler do
  @moduledoc """
  Responsible for passing jobs from the queue to whatever the backend
  responsible for processing them.
  """

  alias AssemblyLine.JobQueue.Server
  alias AssemblyLine.Job

  @check_interval Application.get_env(:assembly_line, :check_interval) || 1000

  @doc """
  Starts job processing for the `queue`.

  Returns `:finished` or `:incomplete`.
  """
  @spec start_all(String.t) :: :finished | :incomplete
  def start_all(queue) do
    queue
    |> process(Server.next_set queue)
  end

  @doc """
  Processes the specified `queue`

  Returns `:finished` if the entire pipeline completes successfuly.  Otherwise
  it returns `{:incomplete, [%AssemblyLine.Job{}]}` where the second part of
  the tuple is a list of `AssemblyLine.Job` structs which failed to process.
  """
  @spec process(String.t, list(AssemblyLine.Job.t)) :: {:incomplete, list(AssemblyLine.Job.t)} | :finished
  def process(queue, jobs)
  def process(_queue, []), do: :finished
  def process(queue, jobs) do
    queue
    |> process_set(jobs)
    |> case do
      {:incomplete, []} ->
        Server.complete_current_set(queue)
        process(queue, Server.next_set(queue))
      {:incomplete, failed} ->
        {:incomplete, failed}
    end
  end

  @doc """
  Processes a set of n jobs.

  Returns `{:incomplete, list}` where `list` is a list of jobs that failed, the
  `list` can be empty.
  """
  @spec process_set(String.t, list(AssemblyLine.Job.t)) :: {:incomplete, list(AssemblyLine.Job.t)} | {:incomplete, []}
  def process_set(queue, jobs) do
    jobs
    |> start_jobs
    |> monitor(queue)
  end

  defp start_jobs(jobs) do
    Enum.reduce(jobs, %{}, fn job, acc ->
      Map.put acc, Task.async(worker_for(job), :perform, [job]), job
    end)
  end

  defp worker_for(%Job{worker: nil}), do: Application.get_env(:assembly_line, :job_executor)
  defp worker_for(job), do: job.worker

  defp monitor(task_map, queue) when map_size(task_map) == 0, do: {:incomplete, Server.next_set(queue)}
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

  defp update_task_map({_t, nil}, task_map, _queue), do: task_map
  defp update_task_map({t, {:ok, response}}, task_map, queue) do
    task_map
    |> Map.get(t)
    |> Job.set_result(response)
    |> Server.finish_job(queue)

    task_map
    |> Map.delete(t)
  end
  defp update_task_map({t, {:exit, _reason}}, task_map, _queue) do
    task_map
    |> Map.delete(t)
  end
end
