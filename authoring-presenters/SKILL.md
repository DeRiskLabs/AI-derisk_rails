---
name: authoring-presenters
title: Authoring Presenters
description: "Write Rails presenters that wrap a view model plus the view/template context and speak the language of the view: labels, links, badges, formatted strings, helper-backed markup, CSS state names, and empty states. Use when a Slim template needs presentation behavior beyond plain field access."
category: authoring
status: active
version: 1.0
applies_to:
  - Ruby
  - Rails
  - Slim
priority: REQUIRED
triggers:
  - presenter
  - presentation logic
  - view logic
  - template branching
  - badges
  - links in a view
  - formatted strings
  - decorator with view context
anti_triggers:
  - pure display data with no view context
  - domain decision
  - authorization
  - persistence
user_invocable: true
last_reviewed_at: "2026-06-28"
---

# Authoring Presenters

A presenter wraps a **view model** plus the **view/template context** and speaks the
language of the view. The shape is:

```text
model/domain object -> view model -> presenter -> Slim template
```

View models answer model/domain-language questions. Presenters answer view-language
questions: labels, links, badges, formatted strings, helper-backed markup, CSS state
names, and empty states.

Read [[authoring-view-models]], [[authoring-view-models-and-presenters]],
[[authoring-rails-views]], and [[authoring-user-facing-copy]].

Supporting references:

```text
references/subscription-summary-example.md   # controller, view model, helper, presenter, Slim, I18n
references/presenter-testing.md              # focused presenter specs and rendering checks
```

Read `references/subscription-summary-example.md` when authoring a presenter from
scratch or when the project lacks an established presenter pattern. Read
`references/presenter-testing.md` when adding or changing presenter tests.


## Use When

- A template has conditional display logic, fallback text, formatting, or repeated
  helper calls tied to one view model.
- A helper mostly receives the same object and returns HTML for that object.
- A page needs unit-testable presentation behavior without adopting a larger decorator
  framework.

Do not add a presenter just because a page exists. If the template only reads simple
view-model fields and renders straightforward markup, keep the Slim template plain.


## Workflow

1. Find one cohesive view concern around one view model, such as a badge, link, empty
   state, display name, formatted date, or status label.
2. Move view-only logic into short presenter methods.
3. Leave domain questions on the view model or owning boundary.
4. Leave large markup blocks in Slim partials or components.
5. Update the template so it reads as presentation intent, not branching logic.
6. Add focused presenter specs for branches/fallbacks and a request/system/rendering
   spec when the rendered page matters.


## Placement

Use local project conventions. In Rails-general apps:

```text
app/lib/presenters/<domain>/...    Presenters::<Domain>::...
```

The same rule applies inside engines.


## Helper Shape

Use an explicit presenter class:

```slim
- subscription = present :subscription_summary, with: "Presenters::Billing::SubscriptionSummaryPresenter"
```

The helper supplies view context. The symbol names a view-exposed method returning the
view model. The string is an explicit presenter class name, not inferred from params or
object class names.

The helper should raise clear `ArgumentError`s for missing view-model methods or
presenter constants. Do not broadly rescue errors raised inside the view model or
presenter; those are real implementation bugs.


## Rules

- Presenters take view models, not raw ActiveRecord objects.
- If an existing presenter only delegates model accessors and never uses view context,
  treat it as a view model instead.
- `present(:name, with: "PresenterClass")` expects `name` to be a view-exposed method
  that returns the view model.
- Delegate domain questions to the view model or domain boundary.
- Call helpers explicitly through delegated helper methods or `view_context`; avoid broad
  `method_missing`.
- Use `I18n.t` for all user-facing strings.
- Return safe Rails HTML only through helpers such as `tag`, `content_tag`, `link_to`,
  `safe_join`, or sanitized renderer output.
- Keep queries out of presenters; preload or build the view model before rendering.
- Keep large markup in Slim partials or components; presenters compose small pieces.
- Prefer `present(:view_model_name, with: "PresenterClass")` so the helper supplies
  view context but the presenter class remains explicit.
- Test meaningful presenter branches directly, and add a request/system/rendering test
  for important pages.


## Avoid

- Authorization, validation, persistence, security-sensitive logic, or domain decisions.
- Inferring presenter classes by constantizing arbitrary strings, params, or object
  class names.
- Calling controller-only helpers unless the dependency is deliberately passed or
  stubbed in tests.
- Presenter methods that save records, run queries, or hide state changes.
- Using presenters as a dumping ground for all view helpers.
- Returning hard-coded English strings.


## Completion Criteria

Done when the presenter wraps a view model, exposes short view-language methods, uses
explicit helper delegation and I18n, keeps queries/domain decisions out, and has tests
for meaningful display branches or fallbacks.
