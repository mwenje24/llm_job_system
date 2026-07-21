defmodule LlmJobSystem.Jobs.Job do
  @moduledoc """
  Will defines state transitions
  """
  @enforce_keys [:id, :prompt]

  @type status :: :pending | :running | :retrying | :completed | :failed

  @type t :: %__MODULE__{
    id: String.t(),
    prompt: String.t(),
    status: status(),
    retries: non_neg_integer(),
    max_retries: non_neg_integer(),
    result: String.t(),
    error: term() | nil,
    inserted_at: DateTime.t(),
    started_at: DateTime.t() | nil,
    completed_at: DateTime.t() | nil
  }

  defstruct [
    :id,
    :prompt,
    :started_at,
    :completed_at,
    result: nil,
    error: nil,
    status: :pending,
    retries: 0,
    priority: :normal,
    max_retries: Application.compile_env(
      :llm_job_system,
      :max_retries,
      4
    ),
    inserted_at: DateTime.utc_now()
  ]

  @priorities [:high, :normal, :low]

  def new(prompt, opts \\ []) do
    priority =
      Keyword.get(opts, :priority, :normal)

    unless priority in [:high, :normal, :low] do
      raise ArgumentError,
            "invalid priority: #{inspect(priority)}"
    end

    unless priority in @priorities do
      raise ArgumentError,
        "invalid priority #{inspect(priority)}"
    end

    %__MODULE__{
      id: UUID.uuid4(),
      prompt: prompt,
      priority: priority,
      status: :queued
    }
  end

  @spec start(t()) :: t()
  def start(job) do
    %{
      job
      | status: :running, started_at: DateTime.utc_now(), error: nil
    }
  end

  @spec complete(t(), String.t()) :: t()
  def complete(job, result) do
    %{
      job
      | status: :completed, result: result, completed_at: DateTime.utc_now()
    }
  end

  @spec record_failure(t(), term()) :: t()
  def record_failure(job, reason) do
    %{
      job
      | status: :retrying, error: reason, retries: job.retries + 1
    }
  end

  @spec retry(t) :: t()
  def retry(job) do
    %{
      job
      | status: :pending, error: nil
    }
  end

  @spec mark_failed(t()) :: t()
  def mark_failed(job) do
    %{
      job
      | status: :failed, completed_at: DateTime.utc_now()
    }
  end

  @spec retryable?(t()) :: boolean()
  def retryable?(job) do
    job.retries < job.max_retries
  end


end
