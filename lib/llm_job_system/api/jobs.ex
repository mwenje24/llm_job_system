defmodule LlmJobSystem.Metrics do
  @moduledoc """
  Emits telemetry events for the job system.
  """

  def job_queued(job_id, queue_size) do
    :telemetry.execute(
      [:llm_job_system, :job, :queued],
      %{queue_size: queue_size},
      %{job_id: job_id}
    )
  end

  def job_started(job_id, attempt) do
    :telemetry.execute(
      [:llm_job_system, :job, :started],
      %{system_time: System.system_time()},
      %{
        job_id: job_id,
        attempt: attempt
      }
    )
  end

  def job_completed(job_id, attempt, duration) do
    :telemetry.execute(
      [:llm_job_system, :job, :completed],
      %{duration: duration},
      %{
        job_id: job_id,
        attempt: attempt
      }
    )
  end

  def job_failed(job_id, attempt, duration, reason) do
    :telemetry.execute(
      [:llm_job_system, :job, :failed],
      %{duration: duration},
      %{
        job_id: job_id,
        attempt: attempt,
        reason: inspect(reason)
      }
    )
  end

  def job_retried(job_id, retries) do
    :telemetry.execute(
      [:llm_job_system, :job, :retried],
      %{retry_count: retries},
      %{job_id: job_id}
    )
  end
end
