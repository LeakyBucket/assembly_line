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

  The `AssemblyLine.JobQueue.Server` process can manage more complex graphs as
  well, take the following example:

  ```
                                        A
                                        |
                                        |
                                        v
                        C               B
                        |               |
                        |               |
                        ------> D <------
                                |
                                |
                                v
                                E
  ```

  You could represent the above graph with the following list:

  `[A, [B, C], D, E]`

  While that preserves the dependencies of all the nodes in the graph it isn't
  necessarily the most efficient way to process the `DAG`, if `A` is sufficiently
  slow then `C` is blocked for no real reason.

  In these cases we can flatten the graph using another `AssemblyLine.JobQueue.Server`
  process.  This means you have to create two `Server` processes for one graph
  but it allows for a clean optimization of your work load.  In this case we would
  build the following `AssemblyLine.JobQueue.Server` processes:

  ```
  {:ok, inner} = AssemblyLine.Supervisor.start_queue("inner", [A, B])
  {:ok, outer} = AssemblyLine.Supervisor.start_queue("outer", [[C, "inner"], D, E])
  ```

  Whenever the _Server_ process encounters a string in the list it delegates down
  to that _Server_ process.

  ### The `finished` attribute

  This arrtibute holds a `MapSet` of all the jobs that have been completed for
  the job queue.

  ## The Handler

  The `AssemblyLine.JobQueue.Handler` module simplifies processing the data in
  a specific job queue.  The `Handler` is responsible for pulling work from the
  queue and dispatching it to your worker modules for processing.

  ### Handler Configuration

  There are two application configuration values you can use to modify the
  behavior of the `Handler`.

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

  use Application
  alias AssemblyLine.JobQueue.Supervisor

  def start(_type, _args) do
    Supervisor.start_link
  end
end
