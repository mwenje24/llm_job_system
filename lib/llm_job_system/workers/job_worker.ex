defmodule LlmJobSystem.Workers.JobWorker do
  @moduledoc """
  processes a single job/executes work
  """

  use GenServer

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
    updated_job =
      Job.complete(job, "The job has successfully completed")

    send(
      LlmJobSystem.Jobs.Dispatcher,
      {:job_completed, updated_job}
    )

    {:stop, :normal, updated_job}
  end

end
