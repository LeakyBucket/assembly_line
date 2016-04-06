defmodule AssemblyLine.JobQueue.Server do
  @moduledoc """
  Manages job queues

  The Server module manages the `DAG` state.  It contains all the logic for
  managing said state, as well as defining the structure for jobs and completion
  tracking.
  """

  defstruct work: [], finished: MapSet.new([])

  @doc """
  Starts a new job queue with the given name and task load

  Returns {:ok, pid}

  A new job queue should be initialized will all required work upfront.  The
  work should be in the form of a list of `AssemblyLine.Job` structs.  Each nesting in
  the list can be run in parallel but must finish before the next entry can
  start.

  ## Examples

    Lets say we have three jobs two of those jobs are independent but are
    required before the third can be run.  We would need the following work list:

    ```
      [[%AssemblyLine.Job{}, %AssemblyLine.Job{}], %AssemblyLine.Job{}]
    ```
  """
  def start_link(name, work) do
    Agent.start_link(fn -> %__MODULE__{work: work} end, name: name)
  end

  @doc """
  Fetches the next job set for the named queue

  Returns a list of `AssemblyLine.Job` structs

  next_for will return the first element currently in the work list, note that
  it does not modify the list at all.  You must explicitly indicate that a job
  set is finished via `complete_current_set/1` before it will be removed from
  the list.
  """
  def next_for(name) do
    Agent.get(name, fn %__MODULE__{work: [next | _rest]} ->
      List.wrap next
    end)
  end

  @doc """
  Fetches the set of completed jobs

  Returns a `MapSet` of `AssemblyLine.Job` structs

  get_completed will return all the jobs that have been marked as complete.  This
  is useful when a finished job could have a negative impact if repeated.
  Tracking completed jobs can help prevent re-executing a sensitive job that is
  part of an incomplete job set.
  """
  def get_completed(name) do
    Agent.get(name, fn %__MODULE__{finished: completed} ->
      completed
    end)
  end

  @doc """
  Removes the current job set from the work list and adds the entries to the
  finished set

  Returns `:ok`

  _complete_current_set_ takes the current state does two things:

  * pops the first job group off the list
  * adds each job in that group to the `finished` set

  This function should be called when all the jobs in a group have completed
  successfully.
  """
  def complete_current_set(name) do
    Agent.update(name, fn %__MODULE__{work: [current | remaining], finished: finished} ->
      %__MODULE__{work: remaining, finished: MapSet.union(finished, __MODULE__.to_set(current))}
    end)
  end

  @doc """
  Adds a job to the `finished` set

  Returns `:ok`

  This function is intended to track the successful completion of a job in cases
  where the entire job group didn't complete successfully.  This allows for a
  comparison between the current job set and finished during a retry to avoid
  re-running a potentially slow or dangerous job.
  """
  def complete_job(job, name) do
    Agent.update(name, __MODULE__, :finish_job, [job])
  end

  @doc """
  Stops the JobQueue with `name`

  It returns `:ok` if the JobQueue terminates normally otherwise it will exit.
  """
  def finished(name) do
    Agent.stop name
  end

  @doc """
  Adds a specified job to the `finished` set

  Returns an updated `Server` struct

  This is a callback function for the `Agent` to use when adding tasks to the
  `finished` set outside the scope of the `complete_current_set/1` function.
  """
  def add_to_finished(%__MODULE__{work: work, finished: finished}, tasks) do
    %__MODULE__{work: work, finished: MapSet.union(finished, to_set(tasks))}
  end

  @doc """
  Converts a single item or a list of items into a `MapSet`

  Returns a `%MapSet{}`
  """
  def to_set(jobs) when is_list(jobs) do
    Enum.reduce(jobs, MapSet.new([]), fn job, set ->
      MapSet.put set, job
    end)
  end
  def to_set(jobs) do
    MapSet.new [jobs]
  end
end
