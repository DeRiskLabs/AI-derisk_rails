---
name: testing-factories
title: Authoring FactoryBot Factories
description: Conventions for defining FactoryBot factories used across the spec suite - associations, attribute blocks, traits, namespaced engine models, and the schema annotation footer. Use when adding or changing factories under spec/factories.
category: testing
status: active
version: 1.1
applies_to:
  - Ruby
  - Rails
  - RSpec
  - FactoryBot
priority: REQUIRED
triggers:
  - factory bot factory
  - define factory
  - add trait
  - test data builder
anti_triggers:
  - model spec
  - use case spec
user_invocable: true
last_reviewed_at: 2026-06-03
---


# Authoring FactoryBot Factories

Factories provide the test data the rest of the suite builds on. One file per model under
`spec/factories/<plural_model>.rb`.


## Required Reading

```text
common_agent_skills/derisk_ruby/ruby-testing/SKILL.md
```

Supporting references in this skill:

```text
references/annotated-example.md   # a full factory with traits, annotated
references/checklist.md           # review checklist
```


## Conventions

- `# frozen_string_literal: true`, then `FactoryBot.define do … end`.
- One `factory :model_name` per file; name matches the model.
- Give every attribute a **block** value (`first_name { 'John' }`), even constants.
- Declare associations with an explicit block too: `identity { association(:identity) }` —
  uniform with the block rule and unambiguous. Override at the call site when a specific
  record is needed (`create(:profile, identity: identity)`).
- Column-align the value blocks within each attribute group.
- Use blocks for generated values (`uuid { SecureRandom.uuid }`); prefer `Faker` /
  `sequence` for values that must be unique.
- Keep the `# == Schema Information` annotation footer at the bottom (annotaterb maintains
  it); do not hand-edit it.

```ruby
# frozen_string_literal: true

FactoryBot.define do
  factory :profile do
    identity   { association(:identity) }

    first_name { 'John' }
    last_name  { 'Doe' }
    phone      { '+1 555-123-4567' }
    uuid       { SecureRandom.uuid }
  end
end

# == Schema Information
# ...
```


## Traits

Use traits for meaningful variants rather than ad-hoc overrides scattered across specs. Specs
opt in with `FactoryBot.build(:email_address, :primary)`.

```ruby
FactoryBot.define do
  factory :email_address do
    identity { association(:identity) }
    email    { Faker::Internet.unique.email }

    trait :primary do
      acts_as_primary { true }
    end

    trait :verified do
      verified_at { Time.current }
    end

    trait :unverified do
      verified_at { nil }
    end
  end
end
```


## Namespaced / Engine Models

Models inside a namespace (typically an engine) get a subdirectory and an underscored
factory name with an explicit class:

```ruby
# spec/factories/collab/todo_items.rb

FactoryBot.define do
  factory :collab_todo_item, class: 'Collab::TodoItem' do
    # ...
  end
end
```

Bad — generator scaffold defaults left in place:

```ruby
FactoryBot.define do
  factory :collab_todo_item, class: 'Collab::TodoItem' do
    assignee_id { 1 }            # magic foreign key — use an association
    assigner_id { 1 }
    status      { 'MyString' }   # scaffold junk — use a real value or trait
    content     { 'MyText' }
    due_date    { '2025-03-22' } # hard-coded date — use a relative time block
  end
end
```


## Build vs Create

Define factories so they work with both `build` (no DB) and `create` (persisted). Specs
choose: prefer `build` for validation/method specs, `create` when persistence or associations
are required (see [[testing-models]]).


## Avoid

- bare attribute values without a block.
- bare association shorthand (`identity` alone) — use the explicit
  `identity { association(:identity) }` form.
- leaving generator scaffold defaults in place (`'MyString'`, `'MyText'`, hard-coded dates,
  magic foreign-key integers like `assignee_id { 1 }`) — replace with real blocks,
  `Faker`, or associations.
- baking call-site-specific data into the factory; pass overrides at the call site or add a
  trait.
- editing the schema annotation footer by hand.
