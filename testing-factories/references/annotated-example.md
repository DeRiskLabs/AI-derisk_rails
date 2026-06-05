# Annotated Example — Factory with Traits

Neutral domain: a `subscription` factory. Annotated.

```ruby
# frozen_string_literal: true

FactoryBot.define do
  # One factory per file; name matches the model (file: spec/factories/subscriptions.rb).
  factory :subscription do
    # Association with an explicit block — uniform with the attribute-block rule.
    account       { association(:account) }

    # Every attribute is a block, even constants. Blocks column-aligned per group.
    # The base factory must be VALID for both build and create — status is validated
    # (presence + inclusion), so the base supplies one.
    plan          { 'standard' }
    status        { 'trial' }
    # Public-API models always carry a uuid (additional to the id primary key).
    uuid          { SecureRandom.uuid }
    # Generated/unique values use a block; prefer Faker/sequence for uniqueness.
    reference     { "SUB-#{SecureRandom.hex(4)}" }
    started_at    { Time.current }
    period_end_at { 1.month.from_now }

    # Traits name meaningful variants; specs opt in: build(:subscription, :trial).
    trait :trial do
      status        { 'trial' }
      period_end_at { 14.days.from_now }
    end

    trait :active do
      status { 'active' }
    end

    trait :cancelled do
      status       { 'cancelled' }
      cancelled_at { Time.current }
    end
  end
end

# == Schema Information
# ... (annotaterb maintains this)
```

A namespaced (engine) model gets a subdirectory, an underscored factory name, and an
explicit class:

```ruby
# spec/factories/billing/invoice_lines.rb

FactoryBot.define do
  factory :billing_invoice_line, class: 'Billing::InvoiceLine' do
    invoice      { association(:billing_invoice) }

    description  { Faker::Commerce.product_name }
    amount_cents { 1_000 }
  end
end
```


## Why these choices

- **One factory per model, named for it.** Predictable lookup; keeps factory files small.
- **Explicit association blocks.** `account { association(:account) }` keeps every line in
  the same block form and is unambiguous; override at the call site when a specific record
  is needed (`create(:subscription, account: account)`).
- **Block values everywhere, column-aligned.** FactoryBot evaluates attribute blocks lazily
  per build, so timestamps and generated ids are fresh each time; alignment keeps the
  attribute group scannable.
- **Traits for variants, not call-site overrides.** A trait (`:trial`, `:cancelled`) captures
  a coherent state once, so specs read `build(:subscription, :trial)` instead of repeating
  attribute soup.
- **No scaffold leftovers.** Replace generated `'MyString'` / `assignee_id { 1 }` defaults
  with real blocks, `Faker`, or associations before committing.
- **Valid for both `build` and `create`.** Specs choose; the factory must not assume one.
