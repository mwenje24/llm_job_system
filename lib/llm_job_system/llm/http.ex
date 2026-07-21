defmodule LlmJobSystem.Llm.HTTP do
  @moduledoc """
  Shared HTTP helper for LLM providers.
  """

  @spec post(String.t(), map(), keyword()) ::
          {:ok, String.t()} | {:error, term()}
  def post(url, body, opts \\ []) do
    timeout =
      Application.fetch_env!(
        :llm_job_system,
        :request_timeout
      )

    case Req.post(
           url,
           json: body,
           receive_timeout: timeout,
           connect_options: [timeout: timeout],
           headers: Keyword.get(opts, :headers, [])
         ) do
      {:ok, %{status: 200, body: response}} ->
        {:ok, extract_content(response)}

      {:ok, %{status: status, body: body}} ->
        {:error, {:http_error, status, body}}

      {:error, reason} ->
        {:error, reason}
    end
  end

  defp extract_content(response) do
    get_in(
      response,
      ["choices", Access.at(0), "message", "content"]
    )
  end
end
