---
name: authoring-rake-tasks
title: Authoring Rake Tasks
description: Rake tasks as delivery adapters - parse input, send one public command, report the outcome; no business logic in tasks. Use when adding or changing tasks under lib/tasks.
category: architecture
status: active
version: 1.0
applies_to:
  - Ruby
  - Rails
priority: REQUIRED
triggers:
  - rake task
  - new task
  - one-off script
  - data migration task
anti_triggers:
  - the use case the task calls
user_invocable: true
last_reviewed_at: 2026-06-06
---


# Authoring Rake Tasks

A rake task is a **delivery adapter for an operator** — the command line's
equivalent of a controller action. It parses input, sends one public command, and
reports the outcome. Business logic in tasks is unreviewable, untestable, and
unreachable from anywhere else; it goes in a use case.


## The Shape

```ruby
namespace :billing do
  desc 'Reconcile payouts for one provider'
  task :reconcile, %i[provider] => :environment do |_task, args|
    listener = TaskListener.new
    Billing.reconcile_payouts(provider: args.fetch(:provider), listener: listener)
    abort(listener.errors.join('; ')) if listener.failed?
  end
end
```

- Parse `args`/`ENV`, coerce to the contract's kwargs.
- Send **one** public command (a use case or a context's boundary method) — the
  task is a command caller like any other delivery adapter.
- Map the outcome to operator semantics: stdout for success detail, non-zero exit
  (`abort`) for failure, errors extracted per the failure contract.
- A tiny listener struct (or the calling pattern your app provides) carries the
  callbacks; the task file stays under a screenful.


## Rules

- `lib/tasks/<domain>.rake` in the owning slice (engines carry their own
  `lib/tasks/`); `=> :environment` when the command needs the app.
- Idempotency matters more here than anywhere — operators re-run tasks. The
  guard lives in the use case, not the task.
- Long-running batch work: the task enqueues jobs and exits; it does not loop for
  an hour holding a console session.
- No specs for tasks kept this thin — the use case carries the tested behaviour.
  A task accumulating enough logic to need a spec needs an extraction instead.


## Avoid

- Business logic, model writes, or `update_all` in a task body.
- Multi-command orchestration — that is a use case or user story the task defers to.
- Tasks as the only home of a behaviour (anything a task can do, the app can).
