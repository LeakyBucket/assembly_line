defmodule Dag.Job do
  defstruct task: nil, args: [], state: :pending

  def build([task | args]) do
    %__MODULE__{task: task, args: args}
  end
end
