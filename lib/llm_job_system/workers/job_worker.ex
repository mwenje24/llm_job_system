defmodule LlmJobSystem.Workers.JobWorker do
  @moduledoc """
  processes a single job
  executes work and reports the outcome.
  """

  use GenServer

  require Logger

  alias LlmJobSystem.Metrics
  alias LlmJobSystem.Jobs.Job

  def start_link(%Job{} = job) do
    GenServer.start_link(__MODULE__, job)
  end

  @impl true
  def init(job) do
    state = %{
      job: job,
      started_at: System.monotonic_time()
    }
    send(self(), :process)

    {:ok, state}
  end

  @impl true
  def handle_info(
        :process,
        %{job: job, started_at: started_at}
      ) do
    Logger.info("Processing job #{job.id}")

    Metrics.job_started(job.id, job.retries)

    result =
      LlmJobSystem.Llm.Client.chat(job.prompt)

    duration =
      System.monotonic_time() - started_at

    updated_job =
      case result do
        {:ok, response} ->
          updated_job = Job.complete(job, response)

          Metrics.job_completed(
            updated_job.id,
            updated_job.retries,
            duration
          )

          send(
            LlmJobSystem.Jobs.Dispatcher,
            {:job_completed, updated_job}
          )

          updated_job

        {:error, reason} ->
          updated_job =
            Job.record_failure(job, reason)

          Metrics.job_failed(
            updated_job.id,
            updated_job.retries,
            duration,
            reason
          )

          send(
            LlmJobSystem.Jobs.Dispatcher,
            {:job_failed, updated_job}
          )

          updated_job
      end

    {:stop, :normal, updated_job}
  end

end
