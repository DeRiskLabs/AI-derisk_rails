---
name: prefer-component-architecture
title: Prefer Component-Based Architecture
description: Rails architecture stance for serious applications - keep Rails at the framework edge, put business behavior behind explicit Ruby boundaries, and grow progressively from app/lib namespaces to components, engines, APIs, or services only when the boundary earns it. Use when starting or extending a Rails app, deciding where business logic goes, or tempted to grow service objects inside the main app.
category: architecture
status: active
version: 1.1
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
  - component architecture
anti_triggers:
  - single-file bug fix
  - non-Rails Ruby work
user_invocable: true
last_reviewed_at: "2026-06-27"
---


# Prefer Component-Based Architecture

Builds on [[bounded-contexts]].

Read [[cross-boundary-communication]] when one boundary needs to call another.
Read [[app-lib-placement]] when placing custom Ruby abstractions inside a Rails app
or engine.

Rails is a framework edge: routing, controllers, jobs, mailers, persistence
integration, framework glue, and delivery concerns. Business behavior should live
behind explicit Ruby public interfaces.


## Progressive Shape

Choose the smallest boundary that honestly owns the behavior:

```text
app/lib/<abstraction>/     custom Ruby objects inside the app or engine
components/                pure domain contexts as internal gems
engines/                   contexts that need Rails abstractions
apis/                      delivery boundaries for API endpoint collections
external service           independent deployment, data, or operations
```

Start in `app/lib` when the boundary is still local to the application. Promote to a
component, engine, API engine, or service when ownership, dependency management,
framework needs, isolated testing, deployment, or data boundaries justify the cost.


## Principles

- **Thin framework edges.** Controllers, GraphQL endpoints, jobs, mailers, and rake
  tasks translate and delegate; business logic lives behind plain-Ruby public
  interfaces.
- **Business boundaries before Rails shapes.** Do not make controllers, models,
  callbacks, concerns, or jobs the owner of business rules merely because Rails gives
  them names.
- **Strict boundary crossings.** A bounded context is entered only through its public
  interface. Callers do not reach into internal classes, tables, callbacks, or state.
- **Progressive extraction.** Decompose inside a boundary before promoting the
  boundary. Promotion should make ownership clearer, not scatter behavior.
- **No service-object grab bag.** An `app/services/` directory accumulating
  procedural classes is a smell: name the boundary and give it a public interface.


## Layers Skill Collection

This guidance does not require **derisk_layers**. Plain Ruby objects, namespaced under
`app/lib`, can still express clear boundaries and public protocols.

When **derisk_layers** skills are installed, the workspace has chosen the Layers
architecture. Follow those concrete implementation rules: base classes, generators,
registries, GraphQL endpoints, and testing conventions. Start from
[[rails-app-architecture]]. If **derisk_layers** is not installed, use Rails-general
guidance and do not invent Layers rules.


## Avoid

- Putting meaningful business workflows in controllers, jobs, mailers, rake tasks,
  or model callbacks.
- Treating ActiveRecord inheritance as a domain boundary.
- Creating `app/services` as a dumping ground for unowned procedures.
- Extracting a component, engine, or service before the public interface is clear.
- Splitting by technical type instead of business ownership.


## Completion Criteria

Done when the smallest honest Rails boundary has been chosen, Rails framework code
stays at the edge, business behavior has a public Ruby interface, and promotion beyond
`app/lib` is justified by concrete ownership, dependency, framework, testing,
deployment, or data pressure.
