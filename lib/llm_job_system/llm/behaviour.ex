defmodule LlmJobSystem.Llm.Behaviour do
  @moduledoc """
  Defining LLM behaviour
  """
  @callback chat(String.t()) :: {:ok, String.t()} | {:error, term()}
end
