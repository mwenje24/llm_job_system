LLM Job Processing System

An OTP-based asynchronous job processing system built with Elixir.

This project implements a background job processing pipeline capable of accepting LLM jobs, scheduling them according to priority and concurrency constraints, executing them asynchronously, retrying failures with exponential backoff, collecting telemetry metrics, and supporting multiple LLM providers through a behaviour-driven architecture.

The system also exposes an HTTP API for submitting and monitoring jobs.

Assignment Overview

The objective of this exercise was to design and implement a background job processing system using OTP principles.

The solution demonstrates:

OTP application architecture
Supervision trees
GenServers
Dynamic supervision
Behaviour-driven design
Asynchronous job processing
Priority-based scheduling
Retry mechanisms with exponential backoff
Metrics and telemetry
Configurable LLM providers
Event-driven scheduling
HTTP API integration
Separation between the HTTP layer and the OTP processing core
Requirements Mapping
Requirement	Implementation
Create the Job struct	LlmJobSystem.Jobs.Job
Implement the JobQueue GenServer	LlmJobSystem.Jobs.JobQueue
Implement the Dispatcher	LlmJobSystem.Jobs.Dispatcher
Create the JobWorker	LlmJobSystem.Workers.JobWorker
Implement the LLM behaviour and HTTP client	LlmJobSystem.Llm.Behaviour + LlmJobSystem.Llm.HTTP
Wire up the supervision tree	LlmJobSystem.Application
Implement retries with exponential backoff	LlmJobSystem.Retry.Backoff
Add metrics	LlmJobSystem.Metrics + Telemetry logger
Priority scheduling	High / Normal / Low queues
HTTP API	Plug + Cowboy
Multiple LLM providers	Local + OpenAI clients
Architecture
                         HTTP Client
                              │
                              ▼
                    ┌───────────────────┐
                    │   Plug / Cowboy   │
                    │    HTTP API       │
                    └─────────┬─────────┘
                              │
                              ▼
                    ┌───────────────────┐
                    │    JobQueue       │
                    │    GenServer      │
                    └─────────┬─────────┘
                              │
                    ┌─────────┴─────────┐
                    │                   │
                  High                Normal
                    │                   │
                    └─────────┬─────────┘
                              │
                            Low
                              │
                              ▼
                    ┌───────────────────┐
                    │    Dispatcher     │
                    │     GenServer      │
                    └─────────┬─────────┘
                              │
                              ▼
                    ┌───────────────────┐
                    │ DynamicSupervisor │
                    └─────────┬─────────┘
                              │
                    ┌─────────┼─────────┐
                    ▼         ▼         ▼
                 Worker    Worker    Worker
                    │         │         │
                    └─────────┼─────────┘
                              │
                              ▼
                    ┌───────────────────┐
                    │  LLM Behaviour    │
                    └─────────┬─────────┘
                              │
                       ┌──────┴──────┐
                       ▼             ▼
                 LocalClient    OpenAIClient
                       │             │
                       └──────┬──────┘
                              ▼
                       HTTP Client
                           (Req)
                              │
                    ┌─────────┴─────────┐
                    ▼                   ▼
                Local LLM          OpenAI API


                 Telemetry / Metrics
                        │
                        ▼
                  Metrics Logger
Design Decisions
OTP-first Architecture

The implementation uses native OTP primitives rather than introducing a larger application framework.

Components are isolated by responsibility:

Component	Responsibility
Job	Job state and lifecycle
JobQueue	Queue management and current job state
Dispatcher	Scheduling and concurrency control
JobWorker	Executes a single job
DynamicSupervisor	Supervises dynamically created workers
Retry	Exponential backoff strategy
Metrics	Telemetry instrumentation
LLM Behaviour	Provider abstraction
LLM Client	Selects the configured provider
HTTP	Shared HTTP communication
API Router	HTTP interface to the job system
Job Lifecycle
                  ┌──────────┐
                  │  Queued  │
                  └────┬─────┘
                       │
                       ▼
                  ┌──────────┐
                  │ Running  │
                  └────┬─────┘
                       │
                 ┌─────┴─────┐
                 │           │
              Success      Failure
                 │           │
                 ▼           ▼
            ┌─────────┐   Retryable?
            │Completed│      │
            └─────────┘   ┌──┴──┐
                           │     │
                          Yes    No
                           │     │
                           ▼     ▼
                       Backoff  Failed
                           │
                           ▼
                        Queued
Features
Asynchronous Processing

Jobs are processed asynchronously from the HTTP caller.

Submitting a job does not block while the LLM request is executing.

The API returns 202 Accepted after the job has been queued.

HTTP Request
     │
     ▼
Create Job
     │
     ▼
202 Accepted
     │
     │
     └─────────────── Background Processing
                              │
                              ▼
                           Worker
                              │
                              ▼
                             LLM
Priority Queues

The scheduler supports three priority levels:

High
Normal
Low

Each priority has its own FIFO queue.

High
  ↓
Normal
  ↓
Low

The dispatcher always consumes higher-priority jobs before lower-priority jobs while preserving FIFO ordering within each priority.

Example:

High A
High B
Normal A
Normal B
Low A
Low B
Configurable Concurrency

The maximum number of concurrent workers can be configured.

Example:

config :llm_job_system,
  max_concurrency: 5

If the maximum concurrency is reached, additional jobs remain queued until a worker becomes available.

Retry Strategy

Failed jobs can automatically retry using exponential backoff.

Example delays:

Retry	Delay
1	1 second
2	2 seconds
3	4 seconds
4	8 seconds

Maximum retries are configurable.

The retry flow is:

Job Failure
     │
     ▼
Is Retryable?
     │
   Yes
     │
     ▼
Calculate Backoff
     │
     ▼
Schedule Retry
     │
     ▼
Requeue Job
     │
     ▼
Dispatcher
LLM Provider Abstraction

The LLM integration uses an Elixir behaviour to provide provider independence.

             LLM Behaviour
                  │
          ┌───────┴────────┐
          │                │
          ▼                ▼
     LocalClient      OpenAIClient
          │                │
          └───────┬────────┘
                  ▼
             HTTP Layer
                Req

The worker does not need to know which LLM provider is being used.

It simply calls:

LlmJobSystem.Llm.Client.chat(prompt)

The configured provider determines which implementation is used.

Local Provider

Example configuration:

LLM_PROVIDER=local

The local provider can communicate with an OpenAI-compatible local LLM API.

Example:

LLM_BASE_URL=http://localhost:8000
LLM_MODEL=Qwen3.6-35B-A3B
OpenAI Provider

Example configuration:

LLM_PROVIDER=openai

Example:

OPENAI_BASE_URL=https://api.openai.com/v1
OPENAI_MODEL=gpt-4.1-mini
OPENAI_API_KEY=your-api-key

API credentials should never be committed to source control.

Metrics and Telemetry

The system emits Telemetry events during job execution.

Supported events include:

Job queued
Job started
Job completed
Job failed
Job retried

Example event structure:

[:llm_job_system, :job, :started]
[:llm_job_system, :job, :completed]
[:llm_job_system, :job, :failed]
[:llm_job_system, :job, :retried]

The included metrics logger demonstrates how these events can be consumed.

The telemetry architecture can later be extended to monitoring systems such as Prometheus, OpenTelemetry, dashboards, or external observability platforms.

HTTP API

The system exposes an HTTP API using Plug and Cowboy.

The HTTP layer is intentionally kept separate from the OTP processing core.

HTTP Client
     │
     ▼
Plug Router
     │
     ├── JobQueue
     │
     └── Dispatcher
             │
             ▼
        OTP Pipeline
API Endpoints
Method	Endpoint	Description
GET	/api/health	Health check
POST	/api/jobs	Submit a new job
GET	/api/jobs	List jobs
GET	/api/jobs/:id	Retrieve a specific job
Health Check
curl http://localhost:4000/api/health

Response:

{
  "status": "ok"
}
Submit a Job
curl -X POST http://localhost:4000/api/jobs \
  -H "Content-Type: application/json" \
  -d '{
    "prompt": "Explain OTP supervision trees in Elixir",
    "priority": "high"
  }'

Example response:

{
  "id": "8d4...",
  "status": "queued",
  "priority": "high",
  "retries": 0,
  "result": null,
  "error": null
}

The API returns:

202 Accepted

because job execution is asynchronous.

Retrieve a Job
curl http://localhost:4000/api/jobs/JOB_ID

Example:

{
  "id": "8d4...",
  "status": "completed",
  "priority": "high",
  "retries": 0,
  "result": "The LLM response...",
  "error": null
}
List Jobs
curl http://localhost:4000/api/jobs

Example:

{
  "jobs": [
    {
      "id": "8d4...",
      "status": "completed",
      "priority": "high",
      "retries": 0,
      "result": "The LLM response...",
      "error": null
    }
  ]
}
Project Structure
lib/
│
├── api/
│   └── router.ex
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
│   ├── logger.ex
│   └── ...
│
└── application.ex
Supervision Tree

The application uses a supervision tree to provide fault isolation and process supervision.

LlmJobSystem.Supervisor
│
├── Metrics.Logger
│
├── JobSupervisor
│   │
│   ├── JobWorker
│   ├── JobWorker
│   └── JobWorker
│
├── JobQueue
│
├── Dispatcher
│
└── Plug.Cowboy

Workers are dynamically created under JobSupervisor.

If an individual worker terminates, it does not bring down the entire application.

Configuration

Configuration is loaded through the application's configuration system.

Example environment configuration:

LLM_PROVIDER=local

LLM_BASE_URL=http://localhost:8000
LLM_MODEL=Qwen3.6-35B-A3B

OPENAI_BASE_URL=https://api.openai.com/v1
OPENAI_MODEL=gpt-4.1-mini
OPENAI_API_KEY=your-api-key

Other application configuration includes:

config :llm_job_system,
  max_concurrency: 5,
  request_timeout: 30_000,
  max_retries: 4

Provider-specific configuration is maintained separately for local and OpenAI providers.

Security: Never commit .env files or API credentials to Git.

Running
Install Dependencies
mix deps.get
Compile
mix compile
Start the Application
iex -S mix

The HTTP API runs on:

http://localhost:4000
Usage from Elixir
Queue a Normal Priority Job
LlmJobSystem.Jobs.JobQueue.add_job(
  "Explain OTP."
)

The default priority is:

:normal
Queue a High Priority Job
LlmJobSystem.Jobs.JobQueue.add_job(
  "Summarize this article.",
  priority: :high
)
Queue a Low Priority Job
LlmJobSystem.Jobs.JobQueue.add_job(
  "Generate a low-priority report.",
  priority: :low
)
Trigger Dispatch

The dispatcher can be triggered through its public API:

LlmJobSystem.Jobs.Dispatcher.dispatch()
View Jobs
LlmJobSystem.Jobs.JobQueue.list_jobs()
Retrieve a Job
LlmJobSystem.Jobs.JobQueue.get_job(job_id)
Example Processing Flow
HTTP Client
     │
     ▼
POST /api/jobs
     │
     ▼
API Router
     │
     ▼
JobQueue
     │
     ▼
Priority Queue
     │
     ▼
Dispatcher
     │
     ▼
DynamicSupervisor
     │
     ▼
JobWorker
     │
     ▼
LLM Client
     │
     ├───────────────┐
     ▼               ▼
Local LLM        OpenAI API
     │               │
     └───────┬───────┘
             ▼
          Result
             │
             ▼
        Update Job
             │
             ▼
       Emit Telemetry
Error Handling

The system handles several classes of failures:

HTTP failures
LLM provider errors
Request failures
Retry scheduling
Maximum retry limits
Worker process failures
Queue consistency
API validation errors
API 404 responses
JSON-safe serialization of job errors

Provider failures are treated as job failures and can enter the retry workflow when the job remains retryable.

Testing

The project includes a testing plan covering the major components of the system.

The intended test coverage includes:

Job lifecycle
Job state transitions
Queue behaviour
Priority ordering
FIFO behaviour within priorities
Dispatcher scheduling
Concurrency limits
Worker execution
Retry logic
Exponential backoff
LLM provider behaviour
API endpoints
API validation
Error handling

A comprehensive ExUnit suite remains an area for further implementation and expansion.

Future Improvements

The current implementation focuses on the assignment requirements while providing an extensible architecture.

Potential production enhancements include:

Persistent job storage
ETS or PostgreSQL-backed queues
Job cancellation
Manual job retry API
Worker timeout handling
Job result expiration
Dead-letter queues
Rate limiting
Authentication and authorization
API request validation
Graceful shutdown recovery
Distributed job processing
Multiple dispatcher instances
Persistent metrics
Prometheus/OpenTelemetry integration
Comprehensive ExUnit test suite
API documentation using OpenAPI/Swagger
Technologies
Elixir
Erlang/OTP
GenServer
Supervisor
DynamicSupervisor
Plug
Cowboy
Req
Jason
Telemetry
ExUnit
Key Engineering Decisions

The implementation intentionally favors:

Native OTP abstractions
Behaviour-based dependency inversion
Event-driven scheduling
Asynchronous processing
Priority-based job scheduling
Configurable concurrency
Configurable LLM providers
Dynamic supervision
Clear separation of concerns
Thin HTTP layer over the OTP core
Extensibility over premature optimization

The result is a modular architecture where additional LLM providers, scheduling strategies, persistence mechanisms, retry policies, monitoring backends, and API capabilities can be introduced with minimal changes to the existing processing pipeline.

Conclusion

The LLM Job Processing System demonstrates how Elixir/OTP can be used to build a fault-tolerant asynchronous processing system.

The architecture separates:

API
 │
 ▼
Job Management
 │
 ▼
Scheduling
 │
 ▼
Supervision
 │
 ▼
Workers
 │
 ▼
LLM Providers

while Telemetry provides an event-driven mechanism for observing job execution.

The design provides a foundation that can evolve from an in-memory assignment implementation into a production-oriented distributed job processing platform.