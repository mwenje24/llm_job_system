defmodule LlmJobSystem.Jobs.Dispatcher do
  @moduledoc """
  dispatches queued jobs to worker processes - makes scheduling decisions
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
    # The {:DOWN, ref, :process, pid, reason} message will tell us the worker has exited, the Dispatcher can then safely decrement running jobs and free a slot.
    new_state = %{
      state
      | running_jobs: state.running_jobs - 1,
        monitors: Map.delete(state.monitors, ref)
    }

    new_state = dispatch_jobs(new_state)

    {:noreply, new_state}
  end

  @impl true
  def handle_info({:job_completed, job}, state) do
    # The {:job_completed, job} message tells us what happened
    LlmJobSystem.Jobs.JobQueue.update_job(job)

    {:noreply, state}
  end

  @impl true
  def handle_info({:retry_job, job_id}, state) do
    case JobQueue.get_job(job_id) do
      nil ->
        {:noreply, state}

      job ->
        JobQueue.requeue_job(job)

        send(self(), :dispatch)
        {:noreply, state}
    end
  end

  @impl true
  def handle_info({:job_failed, job}, state) do
    if LlmJobSystem.Jobs.Job.retryable?(job) do
      schedule_retry(job)
    else
      JobQueue.update_job(job)
    end

    {:noreply, state}
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

  defp schedule_retry(job) do
    delay =
      LlmJobSystem.Retry.Backoff.delay(job.retries)

      Process.send_after(
        self(),
        {:retry_job, job.id},
        delay
      )
  end
end
