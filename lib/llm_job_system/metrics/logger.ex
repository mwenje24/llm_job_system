defmodule LlmJobSystem.Metrics.Logger do
  use GenServer

  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, :ok, opts)
  end

  @impl true
  def init(:ok) do
    attach()
    {:ok, %{}}
  end

  def attach do
    :telemetry.attach_many(
      "llm-job-system-logger",
      [
        [:llm_job_system, :job, :queued],
        [:llm_job_system, :job, :started],
        [:llm_job_system, :job, :completed],
        [:llm_job_system, :job, :failed],
        [:llm_job_system, :job, :retried]
      ],
      &handle_event/4,
      nil
    )
  end

  def handle_event(event, measurements, metadata, _config) do
    require Logger

    Logger.info("""
    #{inspect(event)}
    measurements=#{inspect(measurements)}
    metadata=#{inspect(metadata)}
    """)
  end
end
