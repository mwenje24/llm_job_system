defmodule LlmJobSystem.Jobs.JobQueue do
  @moduledoc """
  Store and manages jobs in memory
  Persists latest job state
  """
  use GenServer

  alias LlmJobSystem.Jobs.Job

  # client api

  def start_link(opts \\[]) do
    GenServer.start_link(__MODULE__, %{}, Keyword.put_new(opts, :name, __MODULE__))
  end

  # add new job to the queue
  def add_job(prompt, opts \\ []) when is_binary(prompt) do
    GenServer.call(__MODULE__, {:add_job, prompt, opts})
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

  def requeue_job(job) do
    GenServer.call(__MODULE__, {:requeue_job, job})
  end



  # server callbacks
  @impl true
  def init(_) do
    {:ok,
      %{
        high: :queue.new(),
        normal: :queue.new(),
        low: :queue.new(),
        jobs: %{}
      }
    }
  end

  @impl true
  def handle_call({:add_job, prompt, opts}, _from, state) do
    priority =
      Keyword.get(opts, :priority, :normal)

    job = %Job{
      id: UUID.uuid4(),
      prompt: prompt,
      priority: priority
    }

    queue =
      Map.fetch!(state, priority)

    updated_queue =
      :queue.in(job.id, queue)

    new_state =
      state
      |> Map.put(priority, updated_queue)
      |> Map.put(
        :jobs,
        Map.put(state.jobs, job.id, job)
      )

    {:reply, {:ok, job.id}, new_state}
  end

  @impl true
  def handle_call(:next_job, _from, state) do
    case dequeue(state) do
      {:ok, job, new_state} ->
        {:reply, {:ok, job}, new_state}

      :empty ->
        {:reply, :empty, state}
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

  @impl true
  def handle_call({:requeue_job, job}, _from, state) do
    queue =
      Map.fetch!(
        state,
        job.priority
      )

    updated_queue =
      :queue.in(
        job.id,
        queue
      )

    new_state =
      state
      |> Map.put(job.priority, updated_queue)
      |> Map.put(
        :jobs,
        Map.put(state.jobs, job.id, job)
      )

    {:reply, :ok, new_state}

  end

  defp dequeue(state) do
    with :empty <- pop(state, :high),
        :empty <- pop(state, :normal),
        :empty <- pop(state, :low) do
      :empty
    end
  end

  defp pop(state, priority) do
    queue =
      Map.fetch!(state, priority)

    case :queue.out(queue) do
      {{:value, job_id}, updated_queue} ->
        job =
          state.jobs
          |> Map.fetch!(job_id)
          |> Job.start()

        jobs =
          Map.put(state.jobs, job.id, job)

        new_state =
          state
          |> Map.put(priority, updated_queue)
          |> Map.put(:jobs, jobs)

        {:ok, job, new_state}

      {:empty, _} ->
        :empty
    end
  end

end
