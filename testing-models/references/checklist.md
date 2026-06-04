# common_agent_skills/derisk_rails/testing-models/references/checklist.md


# Review Checklist — Model Specs


## Completeness

- [ ] Every declared association, validation, callback, scope, and public method has
      coverage — the spec documents everything the model file says.
- [ ] Nothing tests Rails/ActiveRecord itself — only what this model declares and does.


## Structure

- [ ] `require 'rails_helper'` and `type: :model`.
- [ ] Grouped by concern: `Associations`, `Validations`, `Callbacks`, then `#method`s.
- [ ] `build` used wherever persistence isn't part of the behaviour; `create` only where
      it is (save callbacks, uniqueness against existing rows, association loading).


## Associations & validations

- [ ] Declared with shoulda one-liners (`belong_to`, `validate_presence_of`, custom matchers).
- [ ] Status constants pinned via `validate_inclusion_of(...).in_array(described_class::PERMITTED_STATUSES)`.
- [ ] Value-dependent validity branched with `context` over a built `subject`.


## Scopes

- [ ] Each declared scope has a describe with one matching and one non-matching record,
      asserting `contain_exactly`.
- [ ] No specs for transition methods (`cancel!` etc.) — a thin model has none; that
      behaviour is a use case, tested there.


## Callbacks & methods

- [ ] Triggering action (`save!`, the method) in a single `execute`; never in an `it`.
- [ ] Return values asserted via `execute_result`.
- [ ] Deltas asserted with `change` block matchers.
- [ ] One expectation per `it`.


## Hygiene

- [ ] `# == Schema Information` footer present and not hand-edited.
