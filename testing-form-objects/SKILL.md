---
name: testing-form-objects
title: Testing Form Objects
description: Spec pattern for ActiveModel::Model form objects covering the attribute contract, form duck typing, validations with error messages, and the domain objects they build. Use when writing or modifying specs under spec/forms.
category: testing
status: active
version: 2.0
applies_to:
  - Ruby
  - Rails
  - RSpec
  - ActiveModel
priority: REQUIRED
triggers:
  - form object spec
  - ActiveModel::Model spec
  - form validation spec
  - form_error_messages spec
anti_triggers:
  - model spec
  - use case spec
  - request spec
user_invocable: true
last_reviewed_at: 2026-06-03
---


# common_agent_skills/derisk_rails/testing-form-objects/SKILL.md


# Testing Form Objects

Form objects (`Forms::*`) are `ActiveModel::Model` classes that validate incoming params and
build the domain objects a use case will persist. Specs cover four things: **the attribute
contract**, **form duck typing**, **validity and error messages under varying params**, and
**the objects the form builds**.


## Required Reading

```text
common_agent_skills/derisk_ruby/ruby-testing/SKILL.md
common_agent_skills/derisk_ruby/always-execute-rspec/SKILL.md
```

Supporting references in this skill:

```text
references/annotated-example.md   # a full form spec, annotated
references/checklist.md           # pre-merge review checklist
```

Authoring the objects under test: [[authoring-form-objects]].


## Structure

- `require 'rails_helper'`.
- `subject(:form) { described_class.new(**params) }`.
- `params` / `valid_params` layering so each context overrides one field. When the form takes
  a handful of named attributes, individual lets per attribute (overridden one per context)
  are an acceptable variant.

```ruby
subject(:form) { described_class.new(**params) }

let(:params) { valid_params }
let(:valid_params) { { customer_name: 'Ada Lovelace', line_items_attributes: [] } }
```


## Attributes

Pin the attribute contract with `respond_to` one-liners — each declared input and each
builder reader:

```ruby
describe 'Attributes' do
  it { is_expected.to respond_to(:customer_name) }
  it { is_expected.to respond_to(:line_items_attributes) }

  it { is_expected.to respond_to(:order) }
  it { is_expected.to respond_to(:line_items) }
end
```


## Form Duck Typing

Forms stand in for ActiveRecord models in controllers and views. Pin the duck type:

```ruby
describe 'Form Duck Typing' do
  it { is_expected.to respond_to(:errors) }
  it { is_expected.to respond_to(:new_record?) }
  it { is_expected.to respond_to(:persisted?) }
  it { is_expected.to respond_to(:valid?) }
end
```


## Validations

Use shoulda-matchers one-liners for simple rules (`include Shoulda::Matchers::ActiveModel`
at the top of the describe), and one `context` per input condition for the rest.

When an example asserts the **aftermath** of validation — `form.errors` content — the
`valid?` call MUST run first via `execute`. Plain validity one-liners are self-contained
and need no `execute`.

```ruby
describe 'Validations' do
  it { is_expected.to validate_presence_of(:customer_name) }

  context 'with an invalid email' do
    let(:params) { valid_params.merge(email: 'invalid') }

    it { is_expected.not_to be_valid }
  end

  context 'with a line item for a missing product' do
    let(:params) { valid_params.merge(line_items_attributes: [{ sku: 'missing' }]) }

    execute do
      form.valid?
    end

    it { is_expected.not_to be_valid }

    it 'adds an error message' do
      expect(form.errors[:line_items]).to be_present
    end
  end
end
```


## Builder Methods

Assert the constructed domain object — a pure incoming query, so the expectation wraps the
call directly. Use `FactoryBot.create` for any record the form must look up. Keep one
expectation per `it`.

```ruby
describe '#order' do
  it 'returns a new order with the customer name' do
    expect(form.order.customer_name).to eq('Ada Lovelace')
  end
end

describe '#line_items' do
  context 'with valid line_items_attributes' do
    let(:product) { FactoryBot.create(:product, sku: 'SKU-1') }
    let(:params)  { valid_params.merge(line_items_attributes: [{ sku: product.sku }]) }

    it 'builds a line item' do
      expect(form.line_items.first).to be_a(LineItem)
    end

    it 'links the line item to the product' do
      expect(form.line_items.first.product_id).to eq(product.id)
    end
  end
end
```

Split independent assertions into separate `it`s (e.g. "builds a line item" and "links the
product") rather than stacking expectations in one example.


## Form Error Messages

`#form_error_messages` reads the aftermath of `valid?`, so it gets `execute`:

```ruby
describe '#form_error_messages' do
  execute do
    form.valid?
  end

  context 'when there are no errors' do
    it 'returns an empty array' do
      expect(form.form_error_messages).to eq([])
    end
  end

  context 'when there are errors' do
    let(:params) { valid_params.merge(customer_name: nil) }

    it 'returns formatted error messages' do
      expect(form.form_error_messages).to include("Customer name can't be blank")
    end
  end
end
```


## Avoid

- multiple expectations per `it`.
- asserting `form.errors` without `execute { form.valid? }` having run.
- asserting persistence — forms build objects; persistence is the caller's job and is
  tested in the caller's specs.


## Preferred Structure

```ruby
# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Forms::Orders::CreateForm do
  include Shoulda::Matchers::ActiveModel

  subject(:form) { described_class.new(**params) }

  let(:params) { valid_params }
  let(:valid_params) { { customer_name: 'Ada Lovelace', line_items_attributes: [] } }


  describe 'Attributes' do
    it { is_expected.to respond_to(:customer_name) }
    it { is_expected.to respond_to(:line_items_attributes) }

    it { is_expected.to respond_to(:order) }
    it { is_expected.to respond_to(:line_items) }
  end


  describe 'Form Duck Typing' do
    it { is_expected.to respond_to(:errors) }
    it { is_expected.to respond_to(:new_record?) }
    it { is_expected.to respond_to(:persisted?) }
    it { is_expected.to respond_to(:valid?) }
  end


  describe 'Validations' do
    it { is_expected.to validate_presence_of(:customer_name) }

    context 'with a line item for a missing product' do
      let(:params) { valid_params.merge(line_items_attributes: [{ sku: 'missing' }]) }

      execute do
        form.valid?
      end

      it { is_expected.not_to be_valid }

      it 'adds an error message' do
        expect(form.errors[:line_items]).to be_present
      end
    end
  end


  describe '#order' do
    it 'returns a new order with the customer name' do
      expect(form.order.customer_name).to eq('Ada Lovelace')
    end
  end
end
```
