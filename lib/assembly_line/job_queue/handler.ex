defmodule AssemblyLine.JobQueue.Handler do
  @moduledoc """
  Responsible for passing jobs from the queue to whatever the backend
  responsible for processing them.

  The Handler consumes work from the specified queue and hands the job records
  to the appropriate workers for processing.  In the case that the
  `AssemblyLine.Job.t` struct doesn't specify a `worker` then the worker will
  be pulled from the Application Envrionment.

  ## Processing a Queue

  Starting the processing of a queue is simple:

  ```
   alias AssemblyLine.JobQueue.Handler

  Handler.start_all "the doc queue"
  ```

  `start_all/1` will execute until all jobs finish or a job exits abnormally.
  It is important to note that the `Handler` functions __will not__ timeout.  They
  will continue to wait on the worker until some form of response is received.
  If you wish to implement a timeout your worker's `perform` function should
  track that and `exit` after the time limit has been reached.

  When a stage in the job queue has multiple jobs which can be executed in
  parallel the `Handler` will keep track of the jobs which succeeded and the
  jobs which failed.  All successful jobs are removed from the set in the
  `AssemblyLine.JobQueue.Server`.  This means it is always safe to re-attempt
  processing in the case of a partial completion.

  ## Configuration

  There are two configuration values which govern the behavior of the `Handler`:

  * `check_interval`
  * `job_executor`

  The `check_interval` determines how many miliseconds the `Handler` waits for
  results from the workers.  If this value is not set then a default of `1000`
  (1 second) will be used.

  If this interval elapses before all the workers have replied the `Handler`
  will proceed to update the job queue state for those jobs that have either
  succeeded or failed to taht point.  It will then resume waiting, this loop
  will continue until all jobs have succeeded or failed.

  The `job_executor` provides an option for setting a default Module that should
  process jobs.  The worker can be set on a per job basis as well so this value
  is entirely optional.
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

  # TODO: Handle nil worker case elegantly.
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
