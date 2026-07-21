# LLM Job Processing System

An OTP-based asynchronous job processing system built with **Elixir**.

This project implements a background job processing pipeline capable of accepting LLM jobs, scheduling them for execution, retrying failures with a backoff, and supporting multiple LLM providers through a behaviour-driven architecture.

---

# Assignment Overview

The objective of this exercise was to design and implement a background job processing system using OTP principles.

The solution demonstrates:

- OTP application architecture
- Supervision trees
- GenServers
- Dynamic supervision
- Behaviour-driven design
- Retry mechanisms
- Metrics tracking
- Configurable LLM providers
- Event-driven scheduling

---

# Requirements Mapping

| Requirement | Status |
|-------------|--------|
| Create the Job struct 
| Implement the JobQueue GenServer
| Implement the Dispatcher
| Create the JobWorker
| Implement the LLM behaviour and HTTP client
| Wire up the supervision tree
| Implement retries with exponential backoff
| Add metrics

---

# Architecture

```
                Client

                   │

             JobQueue
          (GenServer)

                   │

             Dispatcher
          (GenServer)

                   │

        DynamicSupervisor

                   │

          JobWorker (N)

                   │

          LLM Behaviour

         ┌──────────────┐
         │              │
 LocalClient     OpenAIClient

                   │

          HTTP Client (Req)

                   │

        Local LLM / OpenAI API
```

---

# Design Decisions

## OTP-first Architecture

The implementation uses native OTP primitives.

Components are isolated by responsibility:

| Component | Responsibility |
|------------|----------------|
| Job | Job state and lifecycle |
| JobQueue | Queue management and persistence of current job state |
| Dispatcher | Scheduling decisions and concurrency control |
| JobWorker | Executes a single job |
| DynamicSupervisor | Supervises workers |
| Retry | Exponential backoff strategy |
| Metrics | Telemetry instrumentation |
| LLM Behaviour | Provider abstraction |

---

# Job Lifecycle

```
Queued
   │
   ▼
Running
   │
   ├──────────────┐
   │              │
Success        Failure
   │              │
Completed    Retry?
                  │
            Yes ──┘
                  │
                  ▼
              Queued
```

---

# Features

## Asynchronous Processing

Jobs execute independently from the caller.

Workers are dynamically supervised.

---

## Configurable Concurrency

Maximum concurrent workers can be configured.

```elixir
config :llm_job_system,
  max_concurrency: 5
```

---

## Priority Queues

The scheduler supports multiple priority levels.

- High
- Normal
- Low

Dispatcher always consumes:

```
High
↓

Normal
↓

Low
```

while preserving FIFO ordering inside each queue.

---

## Retry Strategy

Failed jobs automatically retry using exponential backoff.

Example delays:

| Attempt | Delay |
|----------|-------|
| 1 | 1 second |
| 2 | 2 seconds |
| 3 | 4 seconds |
| 4 | 8 seconds |

Maximum retries are configurable.

---

## LLM Provider Abstraction

A behaviour-based abstraction allows different providers without changing worker logic.

```
LLM Behaviour
      │
      ├────────── LocalClient
      │
      └────────── OpenAIClient
```

Switching providers only requires configuration.

Example:

```bash
LLM_PROVIDER=local
```

or

```bash
LLM_PROVIDER=openai
```

---

## Metrics

The system emits telemetry events during execution.

Events include:

- Job queued
- Job started
- Job completed
- Job failed
- Job retried

The logger included in this project demonstrates how metrics can be consumed.

---

# Project Structure

```
lib/
│
├── jobs/
│   ├── job.ex
│   ├── job_queue.ex
│   └── dispatcher.ex
│
├── workers/
│   ├── job_worker.ex
│   └── job_supervisor.ex
│
├── llm/
│   ├── behaviour.ex
│   ├── client.ex
│   ├── local_client.ex
│   ├── openai_client.ex
│   └── http.ex
│
├── retry/
│   └── backoff.ex
│
├── metrics/
│   └── logger.ex
│
└── application.ex
```

---

# Configuration

Example `.env`

```bash
LLM_PROVIDER=local

LLM_BASE_URL=http://localhost:8000

LLM_MODEL=Qwen3.6-35B-A3B

OPENAI_API_KEY=your-api-key

OPENAI_MODEL=gpt-4.1-mini
```

Configuration is loaded from `config/config.exs`.

---

# Running

Install dependencies.

```bash
mix deps.get
```

Compile.

```bash
mix compile
```

Start the application.

```bash
iex -S mix
```

---

# Usage

Queue a normal priority job.

```elixir
LlmJobSystem.Jobs.JobQueue.add_job(
  "Explain OTP."
)
```

Queue a high priority job.

```elixir
LlmJobSystem.Jobs.JobQueue.add_job(
  "Summarize this article.",
  priority: :high
)
```

Dispatch jobs.

```elixir
send(
  LlmJobSystem.Jobs.Dispatcher,
  :dispatch
)
```

View jobs.

```elixir
LlmJobSystem.Jobs.JobQueue.list_jobs()
```

---

# Example Flow

```
Client

↓

Queue Job

↓

Dispatcher

↓

Dynamic Supervisor

↓

Worker

↓

LLM

↓

Result

↓

Update Job

↓

Emit Metrics
```

---

# Error Handling

The system handles:

- HTTP failures
- Provider errors
- Retry scheduling
- Maximum retry limits
- Worker supervision
- Queue consistency

---

# Future Improvements

The current implementation intentionally focuses on the assignment requirements.

Potential production enhancements include:

- Persistent queue (ETS/PostgreSQL)
- Job cancellation
- Worker timeout handling
- Graceful shutdown recovery
- Comprehensive ExUnit test suite

---

# Testing

A full ExUnit test suite is planned covering:

- Job lifecycle
- Queue behaviour
- Dispatcher scheduling
- Worker execution
- Retry logic
- LLM provider mocking

---

# Technologies

- Elixir
- OTP
- GenServer
- DynamicSupervisor
- Req
- Telemetry

---

# Key Engineering Decisions

The implementation intentionally favors:

- Native OTP abstractions
- Behaviour-based dependency inversion
- Event-driven scheduling
- Configurable providers
- Clear separation of concerns
- Extensibility over premature optimization

The result is a modular architecture where additional LLM providers, scheduling strategies, persistence mechanisms, and monitoring backends can be introduced with minimal changes to existing components.