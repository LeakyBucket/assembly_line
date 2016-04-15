defmodule AssemblyLine do
  @moduledoc """
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

  use Application
  alias AssemblyLine.JobQueue.Supervisor

  def start(_type, _args) do
    Supervisor.start_link
  end
end
