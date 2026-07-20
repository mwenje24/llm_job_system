import Config

config :llm_job_system,
  llm_provider:
    System.get_env("LLM_PROVIDER", "local"),

  llm_base_url:
    System.get_env("LLM_BASE_URL", "http://192.168.84.7:8001"),

  llm_model:
    System.get_env("LLM_MODEL", "Qwen3.6-35B-A3B"),

  openai_base_url:
    System.get_env("OPENAI_BASE_URL", "https://api.openai.com/v1"),

  openai_api_key:
    System.get_env("OPENAI_API_KEY"),

  openai_model:
    System.get_env("OPENAI_MODEL", "gpt-4.1-mini"),

  max_retries: 4,
  max_concurrency: 5,

  request_timeout: 30_000
