---
name: app-lib-placement
title: Custom Abstraction Placement (app/lib)
description: Placement rule for custom Rails-app Ruby abstractions - put your own non-Rails objects under app/lib/<abstraction>/, never a new top-level app/<abstraction>/ directory. Use after deciding a boundary belongs inside the Rails app or engine rather than in a component, engine, or service.
category: architecture
status: active
version: 1.1
applies_to:
  - Ruby
  - Rails
  - Zeitwerk
priority: REQUIRED
triggers:
  - where do service objects go
  - new abstraction directory
  - create a directory under app
  - app/lib placement
  - where to put poros
  - where to put use cases
anti_triggers:
  - Rails-given types (models, controllers, jobs, mailers)
  - deciding whether to extract a component, engine, or service
user_invocable: true
last_reviewed_at: "2026-06-27"
---


# Custom Abstraction Placement (app/lib)

This is a placement skill, not the whole architecture. Use
[[prefer-component-architecture]] when deciding whether the boundary belongs in the
Rails app, a component, an engine, or a service.

Rails gives its own abstractions homes (`app/models`, `app/controllers`, `app/jobs`, ...).
Abstractions of your own — any kind of object Rails does not define — always live under
`app/lib/<abstraction>/`:

```text
app/lib/use_cases/<domain>/...      UseCases::<Domain>::...
app/lib/user_stories/<domain>/...   UserStories::<Domain>::...
app/lib/queries/<scope>/...         Queries::<Scope>::...
app/lib/forms/<domain>/...          Forms::<Domain>::...
```

The rule applies in the main app and inside every engine: each boundary's own `app/lib`
plays the same role under that boundary's root.


## Why

Zeitwerk roots every `app/*` subdirectory WITHOUT a namespace. A new top-level
`app/<abstraction>/` directory therefore defines un-namespaced constants
(`app/user_stories/billing/charge.rb` → `Billing::Charge`, not
`UserStories::Billing::Charge`) or forces custom autoloader wiring. Under `app/lib/` the
directory structure yields the namespace for free:
`app/lib/user_stories/billing/charge.rb` → `UserStories::Billing::Charge`.

`app/lib` is also autoloaded and eager-loaded like the rest of `app/*` — unlike the
top-level `lib/`, which is not on the autoload paths by default.


## Rules

- Never invent a new top-level `app/<abstraction>/` directory for your own abstractions.
- Name the namespace after the abstraction, plural (`UseCases`, `Queries`, `Forms`).
- Rails-given types stay in their Rails-given homes; do not move them into `app/lib`.
- `app/lib` is not a junk drawer. Objects placed there still need clear ownership,
  public interfaces, and tests through those interfaces.


## Avoid

- `app/services/`, `app/use_cases/`, `app/queries/` — top-level homes for your own types.
- custom `config.autoload_paths` wiring to compensate for a top-level directory.
- parking domain objects in the top-level `lib/` (not autoloaded, outside the app).
