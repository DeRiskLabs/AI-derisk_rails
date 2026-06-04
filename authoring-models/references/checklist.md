# common_agent_skills/derisk_rails/authoring-models/references/checklist.md


# Authoring Checklist — Models

- [ ] `# frozen_string_literal: true`; inherits `ApplicationRecord`.
- [ ] Associations declared (`belongs_to`/`has_many`/`has_one`).
- [ ] Validations express data integrity; scoped with `on:` where lifecycle-specific.
- [ ] Statuses declared via `PERMITTED_STATUSES` + inclusion validation; NO transition
      methods or state-machine logic in the model.
- [ ] Gem macros (`rolify`/`resourcify`, etc.) are declarative one-liners.
- [ ] Defaults set intrinsically (`before_validation`/DB defaults); callbacks never touch
      other objects.
- [ ] Scopes are few and simple; complex/parameterised/multiplying scopes extracted to a
      query object.
- [ ] Public-API model: `uuid` column present as the external identifier, additional to —
      never replacing — the `id` primary key; factory populates `uuid`.
- [ ] Only small, pure, intrinsic accessors (e.g. `full_name`, `trial?`).
- [ ] Shared behaviour extracted to `app/models/concerns`.
- [ ] No service logic, multi-model transactions, external calls, or orchestration callbacks.
- [ ] Cross-object/payload validation pushed to a form, not the model.
- [ ] `# == Schema Information` footer present, not hand-edited.
- [ ] Spec following [[testing-models]] exists and covers every declaration.
