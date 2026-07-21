defmodule LlmJobSystem.Llm.LocalClient do
  @moduledoc """
  Local LLM client.
  """

  @behaviour LlmJobSystem.Llm.Behaviour

  alias LlmJobSystem.Llm.HTTP

  @impl true
  def chat(prompt) do
    config =
      Application.fetch_env!(
        :llm_job_system,
        :local
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

    HTTP.post(
      "#{Keyword.fetch!(config, :base_url)}/v1/chat/completions",
      body
    )
  end
end
