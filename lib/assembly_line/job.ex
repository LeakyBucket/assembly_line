defmodule AssemblyLine.Job do
  @moduledoc """
  Provides the job struct as well as functions for manipulating the job struct

  ## The Job Struct

  This struct is intended to hold the meta-data for a job to be performed.  It
  has the following attributes:

  * `task`
  * `args`
  * `result`

  The `task` attribute usually holds some kind of reference to the entry point
  for the work, that could be an Elixir Module or even another type of reference
  if the job is to be processed by another system/application.

  The `args` attribute should be a list of arguments for the task reference.
  This list should contain the data needed for the job to be executed.

  The `result` attribute holds the outcome of the work.
  """

  defstruct task: nil, args: [], result: nil

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
  def set_result(job, result) do
    struct job, result: result
  end
end
