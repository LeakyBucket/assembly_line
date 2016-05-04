defmodule AssemblyLine.Job do
  @moduledoc """
  Provides the job struct as well as functions for manipulating the job struct

  ## The Job Struct

  This struct is intended to hold the meta-data for a job to be performed.  It
  has the following attributes:

  * `task`
  * `worker`
  * `args`
  * `result`
  * `queue`

  The `task` attribute usually holds some kind of reference to the entry point
  for the work, that could be an Elixir Module or even another type of reference
  if the job is to be processed by another system/application.

  The `worker` attribute holds the name of the module that should perform the
  task.  The module specified here should implement the `AssemblyLine.Worker`
  behaviour.

  The `args` attribute should be a list of arguments for the task reference.
  This list should contain the data needed for the job to be executed.

  The `result` attribute holds the outcome of the work.

  The `queue` attribute is set by the `AssemblyLine.JobQueue.Server` and allows
  for proper job tracking with nested complex graphs (nesting).
  """

  defstruct [task: nil, worker: nil, args: [], result: nil, queue: nil]
  @type t :: %AssemblyLine.Job{task: term, worker: atom, args: list, result: term, queue: String.t}

  @doc """
  Sets the `result` attribute for a Job Struct.

  Returns a Job Struct with the `result` attribute set.

  ## Examples

    ```
    iex> job = %AssemblyLine.Job{task: ZoneCreator, args: [{:add, cname_struct}]}
    iex> AssemblyLine.Job.set_result(job, :ok)
    %AssemblyLine.Job{task: ZoneCreator, args: [{:add, cname_struct}], result: :ok}
    ```
  """
  @spec set_result(AssemblyLine.Job.t, term) :: AssemblyLine.Job.t
  def set_result(job, result) do
    struct job, result: result
  end


  @doc """
  Sets the `queue` attribute for the given Job Struct.

  Returns a Job Struct with the `queue` attribute set.

  ## Examples

    ```
    iex> job = %AssemblyLine.Job{task: ZoneCreator, args: [{:add, cname_struct}]}
    iex> AssemblyLine.Job.set_queue(job, "dns_pipeline")
    %AssemblyLine.Job{task: ZoneCreator, args: [{:add, cname_struct}], result: nil, queue: "dns_pipeline"}
    ```
  """
  @spec register_queue(AssemblyLine.Job.t, String.t) :: AssemblyLine.Job.t
  def register_queue(job, queue) do
    struct job, queue: queue
  end
end
