defmodule LlmJobSystem.Workers.JobSupervisor do
  @moduledoc """
  Dynamically supervises the Job worker processes
  """
  use DynamicSupervisor

  def start_link(opts \\ []) do
    DynamicSupervisor.start_link(
      __MODULE__,
      :ok,
      Keyword.put_new(opts, :name, __MODULE__)
    )
  end

  @impl true
  def init(:ok) do
    DynamicSupervisor.init(
      strategy: :one_for_one,
      max_restarts: 10,
      max_seconds: 60
    )
  end
end
