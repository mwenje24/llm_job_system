defmodule LlmJobSystemTest do
  use ExUnit.Case
  doctest LlmJobSystem

  test "greets the world" do
    assert LlmJobSystem.hello() == :world
  end
end
