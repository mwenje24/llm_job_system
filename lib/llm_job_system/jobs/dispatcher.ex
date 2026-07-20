defmodule LlmJobSystem.Jobs.Dispatcher do
  @moduledoc """
  dispatches queued jobs to worker processes - scheduling
  """

  use GenServer

  alias LlmJobSystem.Jobs.JobQueue
  alias LlmJobSystem.Workers.JobSupervisor
  alias LlmJobSystem.Workers.JobWorker

  ## Client

  def start_link(opts \\ []) do
    GenServer.start_link(
      __MODULE__,
      %{},
      Keyword.put_new(opts, :name, __MODULE__)
    )
  end


  ## Server

  @impl true
  def init(_) do
    {:ok,
     %{
       max_concurrency:
          Application.fetch_env!(
            :llm_job_system,
            :max_concurrency
          ),
        running_jobs: 0,
        monitors: %{}
     }}
  end

  @impl true
  def handle_info(:dispatch, state) do
    state = dispatch_jobs(state)

    {:noreply, state}
  end

  @impl true
  def handle_info({:DOWN, ref, :process, _pid, _reason}, state) do
    new_state = %{
      state
      | running_jobs: state.running_jobs - 1,
        monitors: Map.delete(state.monitors, ref)
    }

    new_state = dispatch_jobs(new_state)

    {:noreply, new_state}
  end


  ## Private

  defp dispatch_jobs(state) do
    available =
      state.max_concurrency - state.running_jobs

    do_dispatch(state, available)
  end

  defp do_dispatch(state, 0), do: state

  defp do_dispatch(state, available) do
    case JobQueue.next_job() do
      {:ok, job} ->
        case DynamicSupervisor.start_child(
               JobSupervisor,
               {JobWorker, job}
             ) do
          {:ok, pid} ->
            ref = Process.monitor(pid)

            new_state = %{
              state
              | running_jobs: state.running_jobs + 1,
                monitors: Map.put(state.monitors, ref, pid)
            }

            do_dispatch(new_state, available - 1)

          {:error, reason} ->
            IO.inspect(reason,
              label: "Failed to start worker"
            )

            state
        end

      :empty ->
        state
    end
  end
end
