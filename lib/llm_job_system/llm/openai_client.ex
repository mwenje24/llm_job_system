defmodule LlmJobSystem.Llm.OpenAIClient do
  @moduledoc """
  Client for the OpenAI Chat Completions API.
  """

  @behaviour LlmJobSystem.Llm.Behaviour

  alias LlmJobSystem.Llm.HTTP

  @impl true
  def chat(prompt) do
    config =
      Application.fetch_env!(
        :llm_job_system,
        :openai
      )

    body = %{
      model: Keyword.fetch!(config, :model),
      messages: [
        %{
          role: "user",
          content: prompt
        }
      ]
    }

    headers = [
      {"authorization", "Bearer #{"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"}"}
    ]

    HTTP.post(
      "#{Keyword.fetch!(config, :base_url)}/chat/completions",
      body,
      headers: headers
    )
  end
end
