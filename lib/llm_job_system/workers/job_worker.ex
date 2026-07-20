defmodule LlmJobSystem.Workers.JobWorker do
  @moduledoc """
  processes a single job
  """

  use GenServer

  alias LlmJobSystem.Jobs.Job
  alias LlmJobSystem.Jobs.JobQueue

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
    updated_job =
      Job.complete(
        job,
        "The job has successfully completed"
      )

      JobQueue.update_job(updated_job)

      {:stop, :normal, updated_job}
  end

end
