---
name: authoring-mailers
title: Authoring Mailers
description: Mailers as thin delivery adapters - params in, mail out, I18n subjects, dispatched from jobs; no business logic and no data fetching in mailers. Use when adding or changing mailers.
category: architecture
status: active
version: 1.0
applies_to:
  - Ruby
  - Rails
priority: REQUIRED
triggers:
  - mailer
  - send an email
  - new email
anti_triggers:
  - the use case or observer that triggers the email
user_invocable: true
last_reviewed_at: 2026-06-06
---


# Authoring Mailers

A mailer renders and addresses one email from the values it is handed. It fetches
nothing, decides nothing — the decision to send and the data to send with were made
upstream (observer → job → mailer).


## The Shape

```ruby
module Mailroom
  class VerificationMailer < ApplicationMailer
    def verification_email
      @email_address = params[:email_address]
      @verification_url = params[:verification_url]

      mail(
        to: @email_address,
        subject: I18n.t('auth.verification.email.subject'),
      )
    end
  end
end
```

- `.with(params)` in, instance variables for the template, `mail(...)` out.
- Subjects (and all copy) through I18n.
- Mailers are Rails-facing: they live in engines under the engine constant
  (a dedicated mail engine like `mailroom` is the house pattern), inheriting the
  engine-local `ApplicationMailer`.


## The Dispatch Chain

```text
use case → observer (side effect) → job → mailer.deliver_now
```

- The use case stays focused on its transaction; the observer reacts to the
  outcome; the job defers and retries; the mailer renders. Each link thin.
- `deliver_now` inside a job (the job already provides the async boundary);
  `deliver_later` only when no job wraps the dispatch.


## Rules

- Params are primitives and uuids-resolved-upstream — a mailer receives the email
  address and the url, not a record to interrogate.
- One mailer method = one email. Shared layout/partials carry the branding.
- Testing: a mailer spec pins the envelope (to, subject) and the key body content
  (the url present); the *decision* to send is pinned in the observer's or job's
  spec, not here.


## Avoid

- Queries, model lookups, or any `find` inside a mailer.
- Conditional sending logic in the mailer (decide upstream).
- Hard-coded copy or subjects.
- Calling mailers directly from use cases — side effects ride observers.
