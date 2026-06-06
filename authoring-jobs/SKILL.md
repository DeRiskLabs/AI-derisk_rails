---
name: authoring-jobs
title: Authoring Jobs
description: Background jobs as thin async delivery adapters - a job defers a public command or performs one delivery side effect, and holds no business logic. Use when adding or changing classes under app/jobs.
category: architecture
status: active
version: 1.0
applies_to:
  - Ruby
  - Rails
priority: REQUIRED
triggers:
  - background job
  - new job
  - enqueue
  - async work
anti_triggers:
  - the use case the job calls
  - queue infrastructure configuration
user_invocable: true
last_reviewed_at: 2026-06-06
---


# Authoring Jobs

A job is a **thin async delivery adapter**: the queue is good at deferral and retry;
business logic in jobs is not. Queues deliver at-least-once, so a job body must
tolerate running twice.

A job's body is one of exactly two things:

1. **Defer a command** — deserialize kwargs, send one public command (a use case or a
   context's boundary method), map the outcome to queue semantics (raise to retry,
   return to discard).
2. **Perform one delivery side effect** — dispatch a mailer, push a notification,
   call one external service.

Nothing else. If a job branches on domain state, the branch belongs in the use case.


## Placement and Shape

```text
app/jobs/<name>_job.rb                      # main-app jobs
engines/<engine>/app/jobs/<engine>/...      # engine jobs, under the engine constant
```

Jobs are Rails-facing classes: engine jobs take the engine constant
(`Mailroom::SendVerificationEmailJob`) and inherit the engine-local
`ApplicationJob`.

```ruby
module Mailroom
  class SendVerificationEmailJob < ApplicationJob
    queue_as :default

    def perform(email_address:, verification_url:)
      VerificationMailer.with(
        email_address: email_address,
        verification_url: verification_url,
      ).verification_email.deliver_now
    end
  end
end
```


## Rules

- **Keyword arguments only**, primitives and uuids — job args are serialized; never
  enqueue a record when a uuid will re-fetch it fresh at perform time.
- **Idempotent by design**: running twice must be safe (look up by uuid and no-op
  when already done; rely on the use case's own guards).
- **Outcome → queue semantics**: raise to engage retry; rescue-and-return (or simply
  return) to discard. Decide per job which failure means which.
- **Who enqueues**: observers and callers enqueue jobs as side effects; a use case's
  `#call` body stays focused on its transactional work.
- One job = one deferral. A job fanning out into multiple commands is orchestration —
  that belongs in a use case or user story the job defers to.


## Avoid

- Business logic, domain branching, or multi-step orchestration in `perform`.
- Positional job arguments.
- Serializing whole records into the queue.
- Jobs calling user stories (a user story is a user-interaction boundary; a job is
  not a user).
