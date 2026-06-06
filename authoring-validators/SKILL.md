---
name: authoring-validators
title: Authoring Validators
description: Custom ActiveModel validators - small, single-format EachValidators in app/validators, shared vocabulary across forms and models, I18n messages. Use when extracting or writing a reusable validation.
category: architecture
status: active
version: 1.0
applies_to:
  - Ruby
  - Rails
priority: REQUIRED
triggers:
  - custom validator
  - validates with
  - extract a validation
anti_triggers:
  - inline validates declarations that need no extraction
user_invocable: true
last_reviewed_at: 2026-06-06
---


# Authoring Validators

A custom validator is a **reusable rule with a name** — extracted when the same
check appears in more than one form/model, or when an inline lambda obscures what
is being validated. Validation itself lives primarily in forms (and intrinsically
in models); validators are the shared vocabulary they draw on.


## The Shape

```ruby
class EmailAddressValidator < ActiveModel::EachValidator
  def validate_each(record, attribute, value)
    return if value.blank? && options[:allow_blank]
    return if value.nil? && options[:allow_nil]
    return if value.to_s.match?(URI::MailTo::EMAIL_REGEXP)

    record.errors.add(attribute, options[:message] || :invalid_format)
  end
end
```

used as:

```ruby
validates :email, email_address: true
validates :backup_email, email_address: { allow_blank: true }
```


## Rules

- `app/validators/<rule>_validator.rb`, top-level constant — validators are shared
  vocabulary, not context internals. A rule used by exactly one engine may live in
  that engine instead.
- One validator = one rule. Composite checks are separate validators composed in
  the `validates` call.
- Honour `allow_blank`/`allow_nil` via options, as above — the caller decides
  presence semantics separately (`presence: true` is its own validation).
- Errors via symbol keys (`:invalid_format`) resolved through I18n — never
  hard-coded message strings; `options[:message]` as the override seam.
- `EachValidator` for attribute rules; `ActiveModel::Validator` with `validate`
  only for genuinely record-level invariants.


## Testing

A dedicated spec per validator, driving a minimal inline model — pin the accepting
cases, the rejecting cases, the option seams (`allow_blank`, `message`), and the
error key. Forms using the validator pin only *that the attribute is validated*,
not the rule's internals again.


## Avoid

- Reaching into the database or other records from `validate_each`.
- Business policy in a validator (eligibility is a use case's concern; format is a
  validator's).
- Duplicating a rule inline that already has a named validator.
