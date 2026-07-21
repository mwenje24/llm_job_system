defmodule LlmJobSystem.Application do
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    LlmJobSystem.Metrics.Logger.attach()

    children = [
      {LlmJobSystem.Workers.JobSupervisor, []},
      {LlmJobSystem.Jobs.JobQueue, []},
      {LlmJobSystem.Jobs.Dispatcher, []}
    ]

    opts = [
      strategy: :one_for_one,
      name: LlmJobSystem.Supervisor
    ]

    Supervisor.start_link(children, opts)
  end
end
