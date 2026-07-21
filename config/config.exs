import Config

config :llm_job_system,
  llm_provider: System.get_env("LLM_PROVIDER", "openai"),
  max_retries: 4,
  max_concurrency: 5,
  request_timeout: 30_000,
  local: [
    base_url: System.get_env("LLM_BASE_URL", "http://192.168.84.7:8001"),
    model: System.get_env("LLM_MODEL", "Qwen3.6-35B-A3B")
  ],
  openai: [
    base_url: System.get_env("OPENAI_BASE_URL", "https://api.openai.com/v1"),
    api_key: System.get_env("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"),
    model: System.get_env("OPENAI_MODEL", "gpt-4.1-mini")
  ]
