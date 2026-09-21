defmodule LlmJobSystem.API.Router do
  @moduledoc """
  HTTP API for submitting and monitoring LLM jobs.
  """

  use Plug.Router

  alias LlmJobSystem.Jobs.Dispatcher
  alias LlmJobSystem.Jobs.JobQueue

  plug Plug.Logger

  plug Plug.Parsers,
    parsers: [:json],
    json_decoder: Jason

  plug(:match)
  plug(:dispatch)

  get "/health" do
    json_response(conn, 200, %{
      status: "ok"
    })
  end

  post "/api/jobs" do
    case create_job(conn.body_params) do
      {:ok, job} ->
        Dispatcher.dispatch()

        json_response(
          conn,
          202,
          serialize_job(job)
        )

      {:error, :missing_prompt} ->
        json_response(
          conn,
          400,
          %{error: "prompt is required"}
        )

      {:error, :invalid_priority} ->
        json_response(
          conn,
          400,
          %{error: "priority must be high, normal, or low"}
        )
    end
  end

  get "/api/jobs/:id" do
    case JobQueue.get_job(id) do
      nil ->
        json_response(
          conn,
          404,
          %{error: "job not found"}
        )

      job ->
        json_response(
          conn,
          200,
          serialize_job(job)
        )
    end
  end

  get "/api/jobs" do
    jobs =
      JobQueue.list_jobs()
      |> Enum.map(&serialize_job/1)

    json_response(
      conn,
      200,
      %{jobs: jobs}
    )
  end

  match _ do
    json_response(
      conn,
      404,
      %{error: "route not found"}
    )
  end

  ## Private

  defp create_job(%{"prompt" => prompt} = params)
       when is_binary(prompt) and byte_size(prompt) > 0 do
    case parse_priority(Map.get(params, "priority")) do
      {:ok, priority} ->
        case JobQueue.add_job(
               prompt,
               priority: priority
             ) do
          {:ok, job_id} ->
            {:ok, JobQueue.get_job(job_id)}
        end

      :error ->
        {:error, :invalid_priority}
    end
  end

  defp create_job(_params) do
    {:error, :missing_prompt}
  end

  defp parse_priority(nil), do: {:ok, :normal}
  defp parse_priority("high"), do: {:ok, :high}
  defp parse_priority("normal"), do: {:ok, :normal}
  defp parse_priority("low"), do: {:ok, :low}
  defp parse_priority(_), do: :error

  defp serialize_job(job) do
    %{
      id: job.id,
      status: job.status,
      priority: job.priority,
      retries: job.retries,
      result: Map.get(job, :result),
      error: serialize_error(Map.get(job, :error))
    }
  end

  defp serialize_error(nil), do: nil

  defp serialize_error({:http_error, status, body}) do
    %{
      type: "http_error",
      status: status,
      message: body
    }
  end

  defp serialize_error(error) do
    %{
      type: "error",
      message: inspect(error)
    }
  end

  defp json_response(conn, status, body) do
    conn
    |> put_resp_content_type("application/json")
    |> send_resp(status, Jason.encode!(body))
  end
end
