---
name: authoring-user-facing-copy
title: Authoring User-Facing Copy
description: "Put every string shown to end users through Rails I18n, assuming future multilingual support even when only English exists today. Use when adding or changing templates, flash messages, mailers, validation errors, serializers, buttons, labels, headings, empty states, or page text."
category: authoring
status: active
version: 1.0
applies_to:
  - Ruby
  - Rails
  - I18n
priority: REQUIRED
triggers:
  - user-facing text
  - copy
  - flash message
  - validation message
  - button label
  - page heading
  - empty state
  - mailer subject
  - translation
  - I18n
anti_triggers:
  - internal log message
  - developer-only exception message
user_invocable: true
last_reviewed_at: "2026-06-28"
---

# Authoring User-Facing Copy

All strings that go out to end users use `I18n.t`. Assume multilingual support will be
needed even when the app starts with English only.


## Applies To

- templates and partials
- flash messages
- form labels, hints, placeholders, and buttons
- validation and form errors
- mailer subjects and body copy
- page titles, headings, empty states, and help text
- serializer/API error detail shown to users


## Rules

- Do not hard-code user-visible English in Ruby, Slim, serializers, or mailers.
- Use stable translation keys that describe the product concept, not the current copy.
- Interpolate values through I18n, not string concatenation.
- Keep pluralization in I18n.
- Tests compare against `I18n.t(...)`, not copied literals.
- Add or update the English translation entry with the code change.


## Avoid

```ruby
flash[:notice] = "Profile updated"
button_tag "Save"
errors.add(:email, "is not allowed")
```

Prefer:

```ruby
flash[:notice] = I18n.t("profiles.update.success")
button_tag I18n.t("profiles.form.save")
errors.add(:email, :not_allowed)
```


## Stop And Ask

Ask before inventing product copy when tone, naming, or legal/compliance wording matters.
