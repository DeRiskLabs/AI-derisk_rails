---
name: prefer-component-architecture
title: Prefer Component-Based Architecture
description: The default architectural stance for Rails applications - a modular monolith of bounded contexts (components, engines, apis) consumed as unbuilt gems, with Rails kept free of business logic. Use when starting an app, deciding where business logic goes, or tempted to grow service objects inside the main app.
category: architecture
status: active
version: 1.0
applies_to:
  - Ruby
  - Rails
priority: REQUIRED
triggers:
  - new rails app
  - app structure
  - where does business logic go
  - service objects
  - modular monolith
  - bounded context
anti_triggers:
  - single-file bug fix
  - non-Rails Ruby work
user_invocable: true
last_reviewed_at: 2026-06-06
---


# Prefer Component-Based Architecture

Rails applications are built as **modular monoliths of bounded contexts**. Rails is
used purely for what it is good at — the web stack, queueing coordination, and
ActiveRecord — and is kept free of business logic.


## The Shape

Bounded slices are unbuilt gems, each family consumed through a Gemfile
`path '<location>' do ... end` block:

```text
apis/         delivery boundaries: collections of API endpoints (REST, GraphQL)
engines/      feature slices that need Rails abstractions (views, jobs, mailers)
components/   pure domain bounded contexts - no Rails inside
lib/          only generic libraries that could be extracted from the app entirely
```

The dividing rule: if a slice needs Rails abstractions it is an engine (under `apis/`
when it is a collection of API endpoints); pure domain logic is a component. The main
application owns all ActiveRecord models, the routing/middleware stack, and boot-time
wiring — and nothing else grows there by default.


## Principles

- **Thin framework edges.** Controllers, GraphQL endpoints, jobs, mailers, and rake
  tasks translate and delegate; business logic lives in plain-Ruby layer objects.
- **Message passing over return values.** Outcomes travel to a listener
  (`success`/`failure` callbacks), never as interrogated return values.
- **Strict boundary crossings.** A bounded context is entered only through its public
  interface; persistence reaches components only through boot-registered repositories.
- **No service-object grab-bag.** An `app/services/` directory accumulating
  procedural classes is the smell this architecture exists to prevent — extract a
  bounded context instead.

The deeper rationale: small, clean bounded contexts are the shape in which both junior
engineers and AI agents work accurately. A context an agent can hold in full is a
context it can change without guessing.


## The House Tool

The `layers` gem implements this architecture: base classes for use cases, user
stories, query objects, jobs, and GraphQL endpoints; the registry components use to
reach persistence; generators and scaffolders for each piece; RuboCop boundary cops
enforcing the direction rules.

When the application uses the layers gem, the **derisk_layers** skill collection
carries the concrete authoring and testing skills — start from its `INDEX.md` and the
rails-app-architecture skill there.
