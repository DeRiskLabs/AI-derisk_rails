# derisk_rails

General Rails skills. Assumes: derisk_common, derisk_ruby.

## Architecture

- [[prefer-component-architecture]] — the default stance: modular monolith of bounded contexts (components, engines, apis); Rails kept free of business logic.
- [[app-lib-placement]] — own abstractions always live under app/lib/<abstraction>/, never a new top-level app/ directory.

## Authoring

- [[authoring-models]] — thin ActiveRecord models.
- [[authoring-form-objects]] — ActiveModel::Model validation + object building.
- [[authoring-serializers]] — JSON:API serializers.

## Testing

- [[testing-models]] — ActiveRecord model specs.
- [[testing-factories]] — FactoryBot factory conventions.
- [[testing-routing]] — routing specs.
- [[testing-rails-requests]] — request specs.
- [[testing-form-objects]] — form-object specs (attributes, duck typing, validations, builders).
