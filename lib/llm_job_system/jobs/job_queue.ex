defmodule LlmJobSystem.Jobs.JobQueue do
  @moduledoc """
  Store and manage jobs in memory
  """
  use GenServer

  alias LlmJobSystem.Jobs.Job

  # client api

  def start_link(opts \\[]) do
    GenServer.start_link(__MODULE__, %{}, Keyword.put_new(opts, :name, __MODULE__))
  end

  # add new job to the queue
  def add_job(prompt) when is_binary(prompt) do
    GenServer.call(__MODULE__, {:add_job, prompt})
  end

  # get the next pending job
  def next_job do
    GenServer.call(__MODULE__, :next_job)
  end

  # update job
  def update_job(%Job{} = job) do
    GenServer.call(__MODULE__, {:update_job, job})
  end

  # get a job by id
  def get_job(job_id) do
    GenServer.call(__MODULE__, {:get_job, job_id})
  end

  # get all jobs
  def list_jobs do
    GenServer.call(__MODULE__, :list_jobs)
  end

  # server callbacks
  @impl true
  def init(_) do
    {:ok,
      %{
        queue: :queue.new(),
        jobs: %{}
      }
    }
  end

  @impl true
  def handle_call({:add_job, prompt}, _from, state) do
    job =
      %Job{
        id: UUID.uuid4(),
        prompt: prompt
      }

    queue =
      :queue.in(job.id, state.queue)

    jobs =
      Map.put(state.jobs, job.id, job
      )

    new_state=
      %{state | queue: queue, jobs: jobs}

    {:reply, {:ok, job.id}, new_state}
  end

  @impl true
  def handle_call(:next_job, _from, state) do
    case :queue.out(state.queue) do
      {{:value, job_id}, queue} ->
        job = Map.fetch!(state.jobs, job_id)

        {:reply, {:ok, job}, %{state | queue: queue}}

      {:empty, _queue} -> {:reply, :empty, state}
    end
  end

  @impl true
  def handle_call({:update_job, job}, _from, state) do
    jobs =
      Map.put(state.jobs, job.id, job)

    {:reply, :ok, %{state | jobs: jobs}}
  end

  @impl true
  def handle_call({:get_job, id}, _from, state) do
    {:reply, Map.get(state.jobs, id), state}
  end

  @impl true
  def handle_call(:list_jobs, _from, state) do
    {:reply, Map.values(state.jobs), state}
  end

end
