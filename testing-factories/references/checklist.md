# Review Checklist — Factories

- [ ] `# frozen_string_literal: true` then `FactoryBot.define do … end`.
- [ ] File at `spec/factories/<plural_model>.rb`; one `factory :model` matching the model.
- [ ] Namespaced models: file under `spec/factories/<namespace>/`, factory name underscored
      (`:collab_todo_item`) with explicit `class: 'Collab::TodoItem'`.
- [ ] Associations declared with explicit blocks (`identity { association(:identity) }`),
      not bare shorthand.
- [ ] Every attribute given a block value (including constants), column-aligned per group.
- [ ] Unique values use `Faker.*.unique` or `sequence`, not a fixed literal.
- [ ] No generator scaffold defaults left in place (`'MyString'`, hard-coded dates, magic
      foreign-key integers).
- [ ] Meaningful variants expressed as `trait`s, not scattered call-site overrides.
- [ ] Factory works with both `build` and `create` (no persistence assumptions baked in).
- [ ] The base factory builds a VALID record — every validated attribute (e.g. `status`)
      has a base value; traits vary it.
- [ ] Public-API models: `uuid` populated (`uuid { SecureRandom.uuid }`) — additional to
      the `id` primary key.
- [ ] `# == Schema Information` footer present, not hand-edited.
- [ ] No call-site-specific data hard-coded into the factory defaults.
