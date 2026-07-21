defmodule LlmJobSystem.Workers.JobWorker do
  @moduledoc """
  processes a single job
  executes work and reports the outcome.
  """

  use GenServer

  require Logger

  alias LlmJobSystem.Jobs.Job

  def start_link(%Job{} = job) do
    GenServer.start_link(__MODULE__, job)
  end

  @impl true
  def init(job) do
    send(self(), :process)

    {:ok, job}
  end

  @impl true
  def handle_info(:process, job) do
    Logger.info("Processing job #{job.id}")

      case LlmJobSystem.Llm.Client.chat(job.prompt) do
        {:ok, response} ->
          updated_job =
            Job.complete(job, response)

          send(
            LlmJobSystem.Jobs.Dispatcher,
            {:job_completed, updated_job}
          )

        {:error, reason} ->
          updated_job =
            Job.record_failure(job, reason)

          send(
            LlmJobSystem.Jobs.Dispatcher,
            {:job_failed, updated_job}
          )
      end

    {:stop, :normal, job}
  end

end
