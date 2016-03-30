defmodule Dag.JobQueue.Server do
  @moduledoc """
  Manages job queues
  """

  defstruct work: [], finished: MapSet.new([])

  def start_link(name, work) do
    Agent.start_link(fn -> %__MODULE__{work: work} end, name: name)
  end

  def next_for(name) do
    Agent.get(name, fn %__MODULE__{work: [next | _rest]} ->
      next
    end)
  end

  def get_completed(name) do
    Agent.get(name, fn %__MODULE__{finished: completed} ->
      completed
    end)
  end

  def complete_current_set(name) do
    Agent.update(name, fn %__MODULE__{work: [current | remaining], finished: finished} ->
      %__MODULE__{work: remaining, finished: MapSet.union(finished, __MODULE__.to_set(current))}
    end)
  end

  def complete_task(name, task) do
    Agent.update(name, __MODULE__, :add_to_finished, [task])
  end

  def finished(name) do
    Agent.stop name
  end

  def add_to_finished(%__MODULE__{work: work, finished: finished}, tasks) do
    %__MODULE__{work: work, finished: MapSet.union(finished, to_set(tasks))}
  end

  def to_set(jobs) when is_list(jobs) do
    Enum.reduce(jobs, MapSet.new([]), fn job, set ->
      MapSet.put set, job
    end)
  end
  def to_set(jobs) do
    MapSet.new [jobs]
  end
end
