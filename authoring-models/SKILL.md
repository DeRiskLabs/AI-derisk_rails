---
name: authoring-models
title: Authoring ActiveRecord Models
description: How to write thin ActiveRecord models - associations, validations, gem macros, defaults, status declarations, simple scopes, and the public-API uuid rule - keeping behaviour in use cases, forms, and query objects. Use when adding or changing files under app/models.
category: architecture
status: active
version: 1.1
applies_to:
  - Ruby
  - Rails
  - ActiveRecord
priority: REQUIRED
triggers:
  - write a model
  - new activerecord model
  - add association or validation
  - add scope or status constant
anti_triggers:
  - service/use case logic
  - query object
  - form object
user_invocable: true
last_reviewed_at: 2026-06-03
---


# common_agent_skills/derisk_rails/authoring-models/SKILL.md


# Authoring ActiveRecord Models

Models are **thin**: they primarily dictate **validations and associations**. Behaviour —
orchestration, multi-step writes, state transitions, complex reads — lives elsewhere
(use cases, forms, query objects).


## Required Reading

None beyond this collection. (When the project uses the layers gem, the derisk_layers
collection's architecture hub explains where models sit in the layer map.)

Supporting references in this skill:

```text
references/annotated-example.md   # a full model, annotated
references/checklist.md           # authoring checklist
```

Test with [[testing-models]]; factories per [[testing-factories]].


## What Belongs in a Model

1. **Associations** — `belongs_to` / `has_many` / `has_one` declare data shape.
2. **Validations** — data integrity; scope with `on: :create`/`on: :update` where the rule
   is lifecycle-specific; `allow_blank`/`format`/`presence` as needed.
3. **Gem macros** — `rolify` / `resourcify` and similar declarative macros are fine.
4. **Default setting** — intrinsic defaults via `before_validation`/`before_save`
   (e.g. generating a name or token when blank), alongside DB column defaults.
5. **Status declarations, not status logic** — a `PERMITTED_STATUSES` constant plus an
   inclusion validation declares the state space. Transitions and state-machine behaviour
   belong in use cases, not the model.
6. **Simple scopes** — fine in the model. When scopes multiply or grow complex (joins,
   parameters, SQL), extract that read behaviour to a query object.
7. **The public-API uuid rule** — any model that ever goes out on a public API has a
   `uuid` column. It is the external identifier at the edges (serializers, look-ups) and
   is **in addition to** the primary key — it never replaces `id`.
8. **Small intrinsic accessors** — pure, local, no side effects (`full_name`, `trial?`).

```ruby
# frozen_string_literal: true

class Subscription < ApplicationRecord
  resourcify # roles can be granted on subscriptions

  belongs_to :account
  has_many :invoices, dependent: :destroy

  PERMITTED_STATUSES = %w[trial active cancelled].freeze

  validates :plan, presence: true
  validates :status, presence: true, inclusion: { in: PERMITTED_STATUSES }

  scope :active, -> { where(status: 'active') }
  scope :trial,  -> { where(status: 'trial') }

  before_validation :set_default_reference, on: :create

  def trial?
    status == 'trial'
  end


  private

  def set_default_reference
    self.reference = "SUB-#{SecureRandom.hex(4)}" if reference.blank?
  end
end
```


## Rules

- No service logic, transactions spanning multiple models, or external calls in the model.
- No state-machine behaviour: the model declares `PERMITTED_STATUSES`; a use case performs
  the transition.
- No query-assembly that belongs in a query object; simple scopes only.
- Validations express *data integrity*; cross-object/payload rules belong in a form
  ([[authoring-form-objects]]).
- Callbacks only for intrinsic, local defaults (a name, a token); never to orchestrate
  other objects.
- Public-API models always carry `uuid` (factories populate it — see [[testing-factories]]);
  `id` stays the primary key and stays internal.
- Extract shared behaviour into `app/models/concerns`.
- Keep the `# == Schema Information` annotation footer (annotaterb); never hand-edit it.


## Avoid

- fat models: business methods, multi-step workflows, notifications.
- transition methods (`cancel!`, `activate!`) that encode state-machine logic — that is a
  use case.
- using callbacks to trigger side effects that belong in a use case.
- a pile of scopes or scopes with joins/SQL — extract a query object.
- exposing `id` externally where `uuid` is the public identifier — and replacing the
  primary key with a uuid.
