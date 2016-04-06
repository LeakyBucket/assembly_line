defmodule AssemblyLine.JobQueue.HandlerTest do
  use ExUnit.Case
  alias AssemblyLine.JobQueue.Handler
  alias AssemblyLine.JobQueue.Server

  @bad_set_server :bad_set
  @happy_server :happy
  @bad_individual_server :bad_seed

  setup do
    {:ok, error_server} = Server.start_link(@bad_set_server, [[:a, :b], [:c, :d], :e])
    {:ok, good_server} = Server.start_link(@happy_server, [[:a, :b], [:d, :e], :f])
    {:ok, single_bad} = Server.start_link(@bad_individual_server, [[:a, :b], :c, [:d, :e]])
    {:ok, error_server: error_server, happy_server: good_server, single_bad: single_bad}
  end

  test "running a successful set" do
    assert {:incomplete, []} = Handler.process_set(@happy_server, [:a, :b])
  end

  test "running an unsuccessful set" do
    Server.complete_current_set(@bad_set_server)

    assert {:incomplete, [:c]} = Handler.process_set(@bad_set_server, [:c, :d])
  end

  test "running a single failing task" do
    Server.complete_current_set(@bad_individual_server)

    assert {:incomplete, [:c]} = Handler.process_set(@bad_individual_server, [:c])
  end
end
