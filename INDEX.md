# derisk_rails

General Rails skills. Assumes: derisk_common, derisk_foundations, derisk_ruby.

## Architecture

- [[prefer-component-architecture]] — Rails as framework edge; start with app/lib boundaries, promote to components/engines/apis/services when earned.
- [[app-lib-placement]] — own Rails-app abstractions live under app/lib/<abstraction>/, not new top-level app/ directories.
- [[framework-edge-adapters]] — Rails framework classes translate input/output and delegate to public boundaries.

## Views & Assets

- [[no-inline-javascript]] — JS never lives in a view: no inline `<script>`, no Slim `javascript:` filter, no `on*=` handlers, no server data interpolated into a script. Use the app's Rails asset convention; pass server data through DOM-safe channels; vendor third-party libraries instead of loading from CDN. REQUIRED.

## Authoring

- [[authoring-models]] — thin ActiveRecord models.
- [[authoring-form-objects]] — ActiveModel::Model validation + object building.
- [[authoring-serializers]] — JSON:API serializers.
- [[authoring-jobs]] — jobs as thin async delivery adapters; idempotency; outcome→queue semantics.
- [[authoring-mailers]] — mailers as thin delivery adapters; params in, mail out; dispatched from jobs.
- [[authoring-validators]] — reusable ActiveModel validators in app/validators; shared vocabulary.
- [[authoring-rake-tasks]] — rake tasks as operator delivery adapters; one public command, no logic.
- [[authoring-user-facing-copy]] — all end-user strings through I18n; assume future multilingual support.
- [[authoring-rails-views]] — Slim templates with semantic accessible HTML, no logic, and view/presenter guidance.
- [[authoring-view-models]] — Rails view models expose model-language display contracts without markup or view helpers.
- [[authoring-view-models-and-presenters]] — decide whether display behavior belongs in a view model, presenter, template, or nowhere new.
- [[authoring-presenters]] — presenters wrap view models with view context for helper-backed presentation behavior.
- [[authoring-stylesheets]] — SCSS/Sass with semantic BEM-style class names.

## Testing

- [[testing-models]] — ActiveRecord model specs.
- [[testing-jobs]] — enqueue side + perform side; never re-test the deferred logic.
- [[testing-factories]] — FactoryBot factory conventions.
- [[testing-routing]] — routing specs.
- [[testing-rails-requests]] — request specs.
- [[testing-form-objects]] — form-object specs (attributes, duck typing, validations, builders).
