# common_agent_skills/derisk_rails/authoring-form-objects/references/checklist.md


# Authoring Checklist — Form Objects


## Placement & shape

- [ ] File at `app/lib/forms/<domain>/<action>_form.rb` (or engine equivalent).
- [ ] Class `Forms::<Domain>::<Action>Form`, `include ActiveModel::Model`.
- [ ] `attr_writer` for internals (`:persisted`); `attr_accessor` for inputs (one per line
      when several).


## Validation & errors

- [ ] `validates`/`validate` cover the rules the form owns (shape, cross-field, existence).
- [ ] Messages via `I18n.t` — no hard-coded strings.
- [ ] `form_error_messages` provided, filtered through a private `report_full_errors_for`
      whitelist (canonical implementation).


## Building & duck typing

- [ ] Builder methods construct domain objects, memoized, and DO NOT save.
- [ ] Look-ups used in validation/building are memoized.
- [ ] `new_record?` / `persisted?` provided: create-style `@persisted ||= false` with
      `attr_writer :persisted`; update-style returns `true`.


## Boundaries

- [ ] No `save`/`update`/persistence (that is the use case).
- [ ] No raw params passed onward unvalidated.


## Verify

- [ ] Spec following [[testing-form-objects]] covers attributes, duck typing, validity,
      error messages, and each builder method.
