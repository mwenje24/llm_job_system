defmodule LlmJobSystem.Jobs.Dispatcher do
  @moduledoc """
  dispatches queued jobs to worker processes - scheduling
  """

  use GenServer

  alias LlmJobSystem.Jobs.JobQueue

  @poll_interval 100

  # client
  def start_link(opts \\ []) do
    GenServer.start_link(
      __MODULE__,
      %{},
      Keyword.put_new(opts, :name, __MODULE__)
    )
  end

  # server
  @impl true
  def init(state) do
    send(self(), :dipatch)

    {:ok, state}
  end

  @impl true
  def handle_info(:dispatch, state) do
    dispatch_job()

    Process.send_after(self(), :dispatch, @poll_interval)

    {:noreply, state}
  end

  defp dispatch_job do
    case JobQueue.next_job() do
      {:ok, job} ->
        DynamicSupervisor.start_child(
          LlmJobSystem.Workers.JobSupervisor,
          {LlmJobSystem.Workers.JobWorker, job}
        )
    end
  end

end
