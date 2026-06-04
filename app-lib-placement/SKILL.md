---
name: app-lib-placement
title: Custom Abstraction Placement (app/lib)
description: Where your own non-Rails abstractions live - always under app/lib/<abstraction>/, never a new top-level app/<abstraction>/ directory. Use when adding a kind of object Rails gives no home (layer objects, service-like objects, POROs) or creating directories under app/.
category: architecture
status: active
version: 1.0
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
anti_triggers:
  - Rails-given types (models, controllers, jobs, mailers)
user_invocable: true
last_reviewed_at: 2026-06-04
---


# common_agent_skills/derisk_rails/app-lib-placement/SKILL.md


# Custom Abstraction Placement (app/lib)

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


## Avoid

- `app/services/`, `app/use_cases/`, `app/queries/` — top-level homes for your own types.
- custom `config.autoload_paths` wiring to compensate for a top-level directory.
- parking domain objects in the top-level `lib/` (not autoloaded, outside the app).
