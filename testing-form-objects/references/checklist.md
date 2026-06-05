# Review Checklist — Form Object Specs


## Structure

- [ ] `require 'rails_helper'`.
- [ ] `subject(:form) { described_class.new(**params) }`.
- [ ] `params` / `valid_params` layering (or individual attribute lets); one input overridden
      per context.


## Contract

- [ ] `describe 'Attributes'` pins each declared input and builder reader with `respond_to`.
- [ ] `describe 'Form Duck Typing'` pins `errors`, `new_record?`, `persisted?`, `valid?`.


## Validations

- [ ] Simple rules use shoulda-matchers one-liners (`include Shoulda::Matchers::ActiveModel`).
- [ ] One `context` per input condition; one assertion each.
- [ ] Any example reading `form.errors` / `#form_error_messages` sits under
      `execute { form.valid? }`.
- [ ] Error-message content asserted for forms that curate errors.


## Builders

- [ ] `describe '#builder_method'` for each method that constructs a domain object.
- [ ] Asserts the built object's class and key attributes.
- [ ] Records the form must look up are created with FactoryBot.
- [ ] Independent assertions split into separate `it`s (no stacked expectations).


## Boundaries

- [ ] No persistence/DB-state assertions (that belongs to the use case).
- [ ] One expectation per `it`.
