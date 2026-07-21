defmodule LlmJobSystem.Retry.Backoff do
  @moduledoc """
  calculating backoff delays
  """

  @base_delay 500

  @spec delay(non_neg_integer()) :: non_neg_integer()
  def delay(retries) do
    trunc(:math.pow(2, retries) * @base_delay)
  end

end
