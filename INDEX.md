# derisk_rails

General Rails skills. Assumes: derisk_common, derisk_ruby.

## Architecture

- [[prefer-component-architecture]] — the default stance: modular monolith of bounded contexts (components, engines, apis); Rails kept free of business logic.
- [[app-lib-placement]] — own abstractions always live under app/lib/<abstraction>/, never a new top-level app/ directory.

## Authoring

- [[authoring-models]] — thin ActiveRecord models.
- [[authoring-form-objects]] — ActiveModel::Model validation + object building.
- [[authoring-serializers]] — JSON:API serializers.
- [[authoring-jobs]] — jobs as thin async delivery adapters; idempotency; outcome→queue semantics.
- [[authoring-mailers]] — mailers as thin delivery adapters; params in, mail out; dispatched from jobs.
- [[authoring-validators]] — reusable ActiveModel validators in app/validators; shared vocabulary.
- [[authoring-rake-tasks]] — rake tasks as operator delivery adapters; one public command, no logic.

## Testing

- [[testing-models]] — ActiveRecord model specs.
- [[testing-jobs]] — enqueue side + perform side; never re-test the deferred logic.
- [[testing-factories]] — FactoryBot factory conventions.
- [[testing-routing]] — routing specs.
- [[testing-rails-requests]] — request specs.
- [[testing-form-objects]] — form-object specs (attributes, duck typing, validations, builders).
