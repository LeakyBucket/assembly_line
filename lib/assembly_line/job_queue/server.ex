defmodule AssemblyLine.JobQueue.Server do
  @moduledoc """
  Provides a common interface for interacting with Job Queues.

  The Server both manages the Job Queues directly and provides an interface for
  interacting with the underlying Job Queues.

  ## The Job Queue

  The Queue is really just a single map with two attributes:

  * `work`
  * `finished`

  ### The `work` attribute

  Holds the remaining work for the queue as well as the order in which that
  work may be performed.  At it's core the `work` is represented as a simple
  list.

  For example, lets say you have the following `DAG`.

                          A               B
                          |               |
                          |               |
                          ------> C <------
                                  |
                                  |
                                  v
                                  D

  The nature of that structure could simply be reflected by the following list:
   `[[a, b], c, d]`.  That is to say each element in the outermost list is a
  requirement for the next element in the list.  If multiple nodes are
  requirements of another node but not of each other then they can be grouped
  together in their own list.

  In order to process the above graph with `AssemblyLine` you simply need to
  pass the following structure to `AssemblyLine.JobQueue.Supervisor.start_queue/2`.

  ```
  [
    [
      %Job{task: :a},
      %Job{task: :b}
    ],
    %Job{task: :c},
    %Job{task: d}
  ]
  ```

  ### The `finished` attribute

  This arrtibute holds a `MapSet` of all the jobs that have been completed for
  the job queue.
  """

  use GenServer
  alias AssemblyLine.Job

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
    GenServer.start_link(__MODULE__, %__MODULE__{work: work}, name: via_tuple(name))
  end

  def handle_call(:next_set, _from, state) do
    {:reply, current_set(state), state}
  end

  def handle_call(:get_completed, _from, state) do
    {:reply, state.finished, state}
  end

  def handle_cast(:complete_current_set, state) do
    %__MODULE__{work: [current | remaining], finished: finished} = state


    {:noreply, %__MODULE__{work: remaining, finished: MapSet.union(finished, to_set(current))}}
  end

  def handle_cast({:complete, job}, state) do
    {:noreply, complete(state, job)}
  end

  @doc """
  Stops the JobQueue with `name`

  It returns `:ok` if the JobQueue terminates normally otherwise it will exit.
  """
  def finished(name) do
    name
    |> via_tuple
    |> GenServer.stop(:normal)
  end

  @doc """
  Adds a specified job to the `finished` set

  Returns an updated `Server` struct

  This function is intended to be used when adding tasks to the `finished` set
  outside the scope of the `complete_current_set/1` function.
  """
  def finish_job(job, queue) do
    GenServer.cast(via_tuple(queue), {:complete, job})
  end

  @doc """
  Fetches the next job set for the named queue

  Returns a list of `AssemblyLine.Job` structs

  next_for will return the first element currently in the work list, note that
  it does not modify the list at all.  You must explicitly indicate that a job
  set is finished via `complete_current_set/1` before it will be removed from
  the list.
  """
  def next_set(queue) do
    GenServer.call(via_tuple(queue), :next_set)
  end

  @doc """
  Fetches the set of completed jobs

  Returns a `MapSet` of `AssemblyLine.Job` structs

  get_completed will return all the jobs that have been marked as complete.  This
  is useful when a finished job could have a negative impact if repeated.
  Tracking completed jobs can help prevent re-executing a sensitive job that is
  part of an incomplete job set.
  """
  def get_completed(queue) do
    GenServer.call(via_tuple(queue), :get_completed)
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
  def complete_current_set(queue) do
    GenServer.cast(via_tuple(queue), :complete_current_set)
  end

  defp complete(%__MODULE__{work: [current | rest], finished: finished}, task) do
    %Job{task: identifier, args: args} = task
    new_current = current
                  |> List.wrap
                  |> List.delete(%Job{task: identifier, args: args, result: nil})

    %__MODULE__{work: [new_current | rest], finished: MapSet.union(finished, to_set(task))}
  end

  defp current_set(%__MODULE__{work: []}), do: []
  defp current_set(%__MODULE__{work: [current | _rest]}) do
    List.wrap current
  end

  defp to_set(jobs) when is_list(jobs) do
    Enum.reduce(jobs, MapSet.new([]), fn job, set ->
      MapSet.put set, job
    end)
  end
  defp to_set(jobs) do
    MapSet.new [jobs]
  end

  defp via_tuple(name) do
    {:via, :gproc, {:n, :l, {:job_queue, name}}}
  end
end
