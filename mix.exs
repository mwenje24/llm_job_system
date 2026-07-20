defmodule LlmJobSystem.MixProject do
  use Mix.Project

  def project do
    [
      app: :llm_job_system,
      version: "0.1.0",
      elixir: "~> 1.17",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger],
      mod: {LlmJobSystem.Application, []}
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:req, "~> 0.5"},
      {:jason, "~> 1.4"},
      {:uuid, "~> 1.1"},
      {:mox, "~> 1.2", only: :test}
    ]
  end
end
