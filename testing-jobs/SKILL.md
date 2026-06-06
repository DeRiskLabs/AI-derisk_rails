---
name: testing-jobs
title: Testing Jobs
description: Spec pattern for background jobs - assert enqueuing from the trigger's side and the outgoing message from the perform side; never re-test the business logic the job defers to. Use when writing or modifying specs for classes under app/jobs.
category: testing
status: active
version: 1.0
applies_to:
  - Ruby
  - Rails
  - RSpec
priority: REQUIRED
triggers:
  - job spec
  - test a job
  - have_enqueued_job
anti_triggers:
  - testing the use case itself
user_invocable: true
last_reviewed_at: 2026-06-06
---


# Testing Jobs

A job is a thin adapter, so its specs are thin: two sides, each with one concern.
The business logic the job defers to is tested in the use case's own specs — never
again here.


## Required Reading

```text
common_agent_skills/derisk_ruby/ruby-testing/SKILL.md
common_agent_skills/derisk_ruby/always-execute-rspec/SKILL.md
```


## The Enqueue Side

Asserted from the **trigger's** spec (the observer, caller, or controller that
enqueues) — enqueuing is an outgoing command:

```ruby
execute { use_case.call }

it 'enqueues the verification email' do
  expect(Mailroom::SendVerificationEmailJob)
    .to have_been_enqueued.with(email_address: email, verification_url: url)
end
```

Use the `:test` queue adapter (`include ActiveJob::TestHelper` /
`ActiveJob::Base.queue_adapter = :test` per suite convention).


## The Perform Side

Perform the job directly and assert the **outgoing message** — the command sent or
the delivery dispatched — per the assertion-target grid:

```ruby
subject(:job) { described_class.new }

let(:mailer) { instance_spy(Mailroom::VerificationMailer) }

before do
  allow(Mailroom::VerificationMailer).to receive(:with).and_return(mailer)
  allow(mailer).to receive(:verification_email).and_return(mailer)
end

execute { job.perform(email_address: email, verification_url: url) }

it 'dispatches the verification mail' do
  expect(mailer).to have_received(:deliver_now)
end
```

For a command-deferring job: stub the public command, assert it was sent with the
deserialized kwargs (and the job as listener where the pattern applies).


## Rules

- One spec file per job, in the owning slice's spec directory.
- Queue mechanics (retry counts, backoff) are the framework's — do not unit-test
  them. Test only *your* mapping: which outcome raises, which returns.
- Idempotency worth pinning: performing twice asserts the second run no-ops, when
  the job carries its own guard.
- No business assertions in job specs — if you are asserting domain state, the
  example belongs in the use case's spec.
