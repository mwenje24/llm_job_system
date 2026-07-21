defmodule LlmJobSystem.Llm.Client do
  @moduledoc """
  Delegates requests to the configured provider.
  """

  alias LlmJobSystem.Llm.LocalClient
  alias LlmJobSystem.Llm.OpenAIClient

  @spec chat(String.t()) ::
          {:ok, String.t()} | {:error, term()}
  def chat(prompt) do
    provider().chat(prompt)
  end

  defp provider do
    case Application.fetch_env!(
           :llm_job_system,
           :llm_provider
         ) do
      "local" ->
        LocalClient

      "openai" ->
        OpenAIClient

      provider ->
        raise ArgumentError,
              "Unsupported LLM provider: #{inspect(provider)}"
    end
  end
end
