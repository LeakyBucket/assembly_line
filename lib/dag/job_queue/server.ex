defmodule Dag.JobQueue.Server do
  @moduledoc """
  Manages job queues
  """

  def start_link(name) do
    Agent.start_link(fn -> [] end, name: name)
  end

  def next_for(name) do
    Agent.get(name, fn [next | rest] ->
      next
    end)
  end

  def complete_current(name) do
    Agent.update(name, fn [current | remaining] ->
      remaining
    end)
  end

  def finished(name) do
    Agent.stop name
  end
end
