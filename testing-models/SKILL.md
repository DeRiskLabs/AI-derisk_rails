---
name: testing-models
title: Testing ActiveRecord Models
description: Spec pattern for ActiveRecord model specs covering associations, validations, callbacks, and instance methods using shoulda-matchers, FactoryBot, and the execute pattern. Use when writing or modifying specs under spec/models.
category: testing
status: active
version: 1.2
applies_to:
  - Ruby
  - Rails
  - RSpec
  - ActiveRecord
  - shoulda-matchers
  - FactoryBot
  - always_execute
priority: REQUIRED
triggers:
  - model spec
  - activerecord spec
  - association validation callback spec
anti_triggers:
  - use case spec
  - request spec
  - form object spec
user_invocable: true
last_reviewed_at: 2026-06-03
---


# Testing ActiveRecord Models

Use this skill for `type: :model` specs of ActiveRecord models.


## Principle: Complete, Fast, Ours

Test **everything the model file declares** — every association, validation, callback,
scope, and public method gets coverage, so the spec documents exactly what we have told
the model to do. But do not re-test Rails: `belong_to` works; what needs pinning is that
*this model declares it*. And do not pay for the database when the behaviour doesn't
need it — `build` by default; persist only where the behaviour itself involves
persistence (callbacks on save, uniqueness against existing rows, association loading).
Some slow tests are necessary; unnecessary ones are waste.


## Required Reading

```text
common_agent_skills/derisk_ruby/ruby-testing/SKILL.md
common_agent_skills/derisk_ruby/always-execute-rspec/SKILL.md
common_agent_skills/derisk_rails/testing-factories/SKILL.md
```

Supporting references in this skill:

```text
references/annotated-example.md   # a full model spec, annotated
references/checklist.md           # pre-merge review checklist
```


## Structure

Group with `describe` by concern: `Associations`, `Validations`, `Callbacks`, then one
`describe '#method'` per public instance method. Use `FactoryBot.build` (no DB) when possible,
`FactoryBot.create` only when persistence or association loading is required.


## Associations and Validations: shoulda one-liners

One-liners pin each declaration at a glance — they assert the declaration exists, not
that Rails implements it correctly:

```ruby
describe 'Associations' do
  it { is_expected.to belong_to(:identity) }
end

describe 'Validations' do
  it { is_expected.to validate_presence_of(:email) }
  it { is_expected.to validate_email_address_of(:email) } # custom matcher
end
```

Status declarations are pinned against the model's own constant:

```ruby
it { is_expected.to validate_inclusion_of(:status).in_array(described_class::PERMITTED_STATUSES) }
```

For value-dependent validity, set `subject` to a **built** record and branch with `context`.
Persist only what the rule checks against (here: the pre-existing primary):

```ruby
describe 'primary email uniqueness' do
  subject(:email_address) { FactoryBot.build(:email_address, :primary, identity: identity) }

  let(:identity) { FactoryBot.create(:identity) }

  context 'when a primary email already exists' do
    before { FactoryBot.create(:email_address, :primary, identity: identity) }

    it { is_expected.not_to be_valid }
  end
end
```


## Callbacks and Methods: the execute pattern

Put the triggering action (`save!`, the method call) in `execute`; assert resulting state or
the return value via `execute_result`. Save-triggered callbacks are one of the places the
database is genuinely needed:

```ruby
describe '#verify!' do
  subject(:email_address) { FactoryBot.create(:email_address, :unverified) }

  let(:verification_code) { email_address.verification_code }

  context 'with the correct code' do
    execute do
      email_address.verify!(verification_code)
    end

    it 'returns true' do
      expect(execute_result).to be true
    end

    it 'clears the verification code' do
      expect(email_address.verification_code).to be_nil
    end
  end
end
```


## Scopes

Each declared scope gets a describe: create one matching and one non-matching record
(a place the database is genuinely needed) and assert the scope returns exactly the
matching set:

```ruby
describe '.active' do
  let!(:active_subscription) { FactoryBot.create(:subscription, :active) }

  before { FactoryBot.create(:subscription, :trial) }

  it 'returns only active subscriptions' do
    expect(described_class.active).to contain_exactly(active_subscription)
  end
end
```


## Change Matchers

For "does it change X" use a `change` block matcher (the action runs inside the
expectation — see the delta-assertion exception in always-execute-rspec):

```ruby
it 'generates a new verification code' do
  expect { email_address.request_verification! }
    .to change(email_address, :verification_code)
end
```


## Schema Annotation

Keep the `# == Schema Information` annotation footer at the bottom of the file (annotaterb
maintains it). Do not hand-edit it.


## Avoid

- multiple expectations per `it`; setup or the action inside an `it` (except block matchers).
- testing Rails/ActiveRecord itself; test what *this* model declares and does.
- `create` where `build` suffices — pay for persistence only when the behaviour needs it.
- leaving any declared association, validation, callback, or public method uncovered.


## Preferred Structure

```ruby
# frozen_string_literal: true

require 'rails_helper'

RSpec.describe EmailAddress, type: :model do
  describe 'Associations' do
    it { is_expected.to belong_to(:identity) }
  end


  describe 'Validations' do
    it { is_expected.to validate_presence_of(:email) }
  end


  describe '#verified?' do
    # Pure query — no persistence involved, so build, not create.
    subject(:email_address) { FactoryBot.build(:email_address, verified_at: verified_at) }

    context 'when verified_at is present' do
      let(:verified_at) { Time.current }

      it { is_expected.to be_verified }
    end

    context 'when verified_at is nil' do
      let(:verified_at) { nil }

      it { is_expected.not_to be_verified }
    end
  end
end

# == Schema Information
# ...
```
