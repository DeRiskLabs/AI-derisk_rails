---
name: authoring-view-models
title: Authoring View Models
description: Use when Rails HTML rendering needs a plain Ruby view model that wraps one domain object or a small page aggregate and exposes model-language, display-ready data for controllers, presenters, or Slim templates. Keeps shape normalization, derived values, and template conditionals out of views without adding markup or view helpers.
category: authoring
status: active
version: 1.0
applies_to:
  - Ruby
  - Rails
priority: RECOMMENDED
triggers:
  - view model
  - display-ready data
  - normalize object shape
  - derived display value
  - logic creeping into view
  - controller exposes view model
anti_triggers:
  - building HTML or calling view helpers
  - trivial single-value access
  - presenter with view context
  - non-Rails Ruby work
user_invocable: true
last_reviewed_at: "2026-06-28"
---

# Authoring View Models

A Rails view model is a plain Ruby object that exposes a small model-language protocol
for display-ready data. It gives controllers, presenters, and Slim templates a stable
display contract without making them know ActiveRecord internals, collaborator shape, or
derived-value rules.

Use [[authoring-presenters]] when the behavior needs view context, helpers, links,
markup, badges, CSS state names, or formatted view-language output. Use
[[authoring-view-models-and-presenters]] when deciding whether the page needs a view
model, presenter, both, or neither.


## Use When

- A template or presenter branches on object shape.
- Callers repeat `respond_to?`, hash-vs-method checks, nil handling, counts, or derived
  values.
- A page needs a stable display contract over one domain object or a small aggregate.

Do not create a view model for trivial field access.


## Rules

- Talk model/domain language, not template language.
- Wrap one domain object by default; page aggregate view models may wrap a small set.
- Expose intention-revealing readers and predicates.
- Normalize collaborator shape inside the view model, so views and presenters do not
  branch on it.
- Do not build HTML, call view helpers, or depend on template context.
- Keep links, badges, CSS state names, helper-backed formatting, and markup in a
  presenter or template layer.
- Controllers build or fetch view models and expose them to templates.


## Shape

```ruby
module ViewModels
  module Billing
    class SubscriptionSummary
      attr_reader :subscription

      def initialize(subscription)
        @subscription = subscription
      end

      def plan_name
        subscription.plan_name
      end

      def status
        subscription.status
      end

      def cancellable?
        subscription.active? && !subscription.cancelled?
      end
    end
  end
end
```


## Testing

Test as a plain Ruby object through public methods. Use simple fakes, structs, or
domain objects as appropriate. Cover each meaningful branch and shape-normalization
case.


## Avoid

- Returning raw collaborators so templates or presenters can branch on internals.
- Method names that describe computation instead of meaning.
- Copying presenter behavior into a view model.
- Adding a view model just because a page exists.


## Completion Criteria

Done when Rails rendering code can ask one small model-language object for
display-ready data, without knowing collaborator shape, private domain internals,
framework helpers, or template context.
