---
name: framework-edge-adapters
title: Rails Framework Edge Adapters
description: "Keep Rails framework classes at the delivery/infrastructure edge: controllers, jobs, mailers, rake tasks, serializers, and templates translate framework input/output and delegate to public boundaries. Use when adding or reviewing Rails edge code."
category: architecture
status: active
version: 1.0
applies_to:
  - Ruby
  - Rails
priority: REQUIRED
triggers:
  - controller action
  - background job
  - mailer
  - rake task
  - serializer
  - template
  - framework edge
  - rails adapter
anti_triggers:
  - pure domain object
  - query internals
  - model validation only
user_invocable: true
last_reviewed_at: "2026-06-28"
---

# Rails Framework Edge Adapters

Rails framework classes are adapters. They translate framework input/output and call a
public boundary. They do not own business workflows.

Read [[prefer-component-architecture]] when deciding where behavior belongs. Read the
specific Rails skill for the edge you are editing.


## Edge Rule

One edge adapter should usually do this:

1. Receive framework input.
2. Normalize or permit the request shape.
3. Call one public command/query boundary.
4. Translate the outcome back to the framework.


## Edge Types

- Controllers translate HTTP, sessions, flash, redirects, and rendered responses.
- Jobs translate queue delivery, retries, and serialized arguments.
- Mailers translate mail delivery params into email.
- Rake tasks translate operator input/output and exit status.
- Serializers translate objects into API response shape.
- Templates translate a view model/presenter into semantic HTML.


## Rules

- Business decisions live behind public Ruby boundaries, not in Rails edge classes.
- Use `I18n.t` for all user-facing strings.
- Pass stable identifiers, params, forms, view models, or public protocol objects across
  the edge.
- Keep error handling consistent with the local framework convention.
- If the edge branches on domain state, move that branch behind a use case, query,
  view model, or presenter.


## Avoid

- Transactions, multi-step workflows, or state transitions in edge classes.
- Fetching through unrelated objects to assemble business behavior.
- Templates, serializers, or mailers deciding domain rules.
- Jobs that orchestrate multiple domain commands.
