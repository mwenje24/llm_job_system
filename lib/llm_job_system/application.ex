defmodule LlmJobSystem.Application do
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      LlmJobSystem.Metrics.Logger,
      {LlmJobSystem.Workers.JobSupervisor, []},
      {LlmJobSystem.Jobs.JobQueue, []},
      {LlmJobSystem.Jobs.Dispatcher, []},
      {
        Plug.Cowboy,
        scheme: :http,
        plug: LlmJobSystem.API.Router,
        options: [
          port: 4000
        ]
      }
    ]

    opts = [
      strategy: :one_for_one,
      name: LlmJobSystem.Supervisor
    ]

    Supervisor.start_link(children, opts)
  end
end
