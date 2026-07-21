# LlmJobSystem

**TODO: Add description**

## Installation

If [available in Hex](https://hex.pm/docs/publish), the package can be installed
by adding `llm_job_system` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:llm_job_system, "~> 0.1.0"}
  ]
end
```

Documentation can be generated with [ExDoc](https://github.com/elixir-lang/ex_doc)
and published on [HexDocs](https://hexdocs.pm). Once published, the docs can
be found at <https://hexdocs.pm/llm_job_system>.


test samples
start IEx

>{:ok, job_id} = LlmJobSystem.Jobs.JobQueue.add_job("Explain OTP in simple terms.")

You should get something like

{:ok, "7d22d4b8-5a1b-4b3e-a1f5-..."}

Retrieve the job

>job = LlmJobSystem.Jobs.JobQueue.get_job(job_id)

You should get something like

%LlmJobSystem.Jobs.Job{
  id: "e5943fee-deac-435f-9e0e-3e1db5ebcd80",
  prompt: "Explain OTP in simple terms.",
  started_at: nil,
  completed_at: nil,
  result: nil,
  error: nil,
  status: :pending,
  retries: 0,
  max_retries: 4,
  inserted_at: ~U[2026-07-20 12:45:03.474173Z]
}

Inspect all jobs

>LlmJobSystem.Jobs.JobQueue.list_jobs()

You should get something like

%LlmJobSystem.Jobs.Job{
  id: "e5943fee-deac-435f-9e0e-3e1db5ebcd80",
  prompt: "Explain OTP in simple terms.",
  started_at: nil,
  completed_at: nil,
  result: nil,
  error: nil,
  status: :pending,
  retries: 0,
  max_retries: 4,
  inserted_at: ~U[2026-07-20 12:45:03.474173Z]
}
iex(9)> LlmJobSystem.Jobs.JobQueue.list_jobs()
[
  %LlmJobSystem.Jobs.Job{
    id: "3e1809fb-c41a-4010-8614-4751fb4174d9",
    prompt: "Explain OTP in simple terms.",
    started_at: nil,
    completed_at: nil,
    result: nil,
    error: nil,
    status: :pending,
    retries: 0,
    max_retries: 4,
    inserted_at: ~U[2026-07-20 12:45:03.474173Z]
  },
  %LlmJobSystem.Jobs.Job{
    id: "e5943fee-deac-435f-9e0e-3e1db5ebcd80",
    prompt: "Explain OTP in simple terms.",
    started_at: nil,
    completed_at: nil,
    result: nil,
    error: nil,
    status: :pending,
    retries: 0,
    max_retries: 4,
    inserted_at: ~U[2026-07-20 12:45:03.474173Z]
  }
]


add multiple jobs

>for i <- 1..5 do  LlmJobSystem.Jobs.JobQueue.add_job("Job #{i}")end


You should get something like

[
  ok: "56208567-758a-4651-a130-d5211757227f",
  ok: "f05275d5-a89b-4151-b7ab-d16393be6f65",
  ok: "150daf54-99a3-4e1c-8eab-0dbc6f5a06c2",
  ok: "d142779c-eb3e-453a-9d87-6c0ad0a68ee6",
  ok: "46bb3acb-d29a-4c67-9d1f-1b7ce7df576d"
]


trying out backoff implementation

>LlmJobSystem.Retry.Backoff.delay(0)

You should get something like
500

