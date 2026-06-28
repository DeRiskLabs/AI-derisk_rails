---
name: authoring-view-models-and-presenters
title: Authoring View Models And Presenters
description: "Decide whether Rails display behavior belongs in a view model, presenter, template, or no new object. Use when a template needs branching, formatting, labels, links, state names, derived display values, or a shaped display contract."
category: authoring
status: active
version: 1.0
applies_to:
  - Ruby
  - Rails
priority: REQUIRED
triggers:
  - view model
  - presenter
  - template logic
  - display formatting
  - derived display value
  - view branching
  - page state
anti_triggers:
  - API serializer
  - ActiveRecord model validation
user_invocable: true
last_reviewed_at: "2026-06-28"
---

# Authoring View Models And Presenters

View models and presenters protect templates from logic when a template has real
presentation complexity. Do not create them for simple field display.

Use this skill to decide which side owns a display concern. Read
[[authoring-view-models]] for Rails view-model rules. Use [[authoring-presenters]] for
presenter implementation details and its worked references.

- **View models** talk the language of the model/domain. They expose view-ready data
  without making the template know ActiveRecord internals.
- **Presenters** talk the language of the view. They handle labels, formatting,
  conditional display, links, badges, CSS state names, empty states, and helper use.

Controllers expose view models to templates, not raw model objects. The template
presents the view model for its context.


## Use Only When Needed

Do not add a view model or presenter just because a page exists.

Use plain Slim with existing objects when the template only reads simple fields and
renders straightforward markup. Add a view model when the template needs a shaped
display contract. Add a presenter when the shaped data needs view-language behavior:
helpers, links, labels, badges, formatting, empty states, or CSS state names.


## Placement

Use local project conventions. In Rails-general apps, prefer `app/lib` for custom
abstractions:

```text
app/lib/view_models/<domain>/...   ViewModels::<Domain>::...
app/lib/presenters/<domain>/...    Presenters::<Domain>::...
```


## Rules

- A view model may wrap one or more domain/model objects and expose stable read methods
  in model/domain language.
- A presenter wraps a view model plus view context; use
  `present(:view_model_name, with: "PresenterClass")` when a helper is available.
- Controllers build or fetch view models and expose them to templates.
- Keep database queries out of presenters and templates.
- Keep domain decisions out of presenters; ask the view model or domain boundary for
  state.
- Keep copy in I18n keys, even when selected by a presenter.
- Test meaningful presenter branches directly when they encode display behavior; add a
  request/system/rendering test for important pages.


## Avoid

- Passing raw ActiveRecord objects into templates when the view needs a shaped contract.
- Building view models inside partials.
- Presenters that save records, run queries, or decide business rules.
- Presenters wrapping raw ActiveRecord objects when a view model should define the
  template contract.
- View models that contain helper-dependent HTML generation.


## Completion Criteria

Done when simple pages stay simple, complex templates get a view-model contract,
presenters handle only view-language behavior, and templates no longer find values or
branch on domain details.
