defmodule LlmJobSystem.Jobs.Job do
  @moduledoc """
  Single LLM processing job
  """
  @enforce_keys [:id, :prompt]

  @type status :: :pending | :running | :completed | :failed

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
    max_retries: Application.compile_env(
      :llm_job_system,
      :max_retries,
      4
    ),
    inserted_at: DateTime.utc_now()
  ]

end
