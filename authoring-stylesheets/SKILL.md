---
name: authoring-stylesheets
title: Authoring Rails Stylesheets
description: "Write Rails styles in Sass/SCSS with semantic class names and BEM-style structure. Use when adding or changing page, component, partial, or view styling in Rails HTML."
category: authoring
status: active
version: 1.0
applies_to:
  - Rails
  - Sass
  - SCSS
  - HTML
priority: REQUIRED
triggers:
  - stylesheet
  - scss
  - sass
  - css class
  - BEM
  - style a view
  - semantic class names
anti_triggers:
  - JSON API only
  - backend-only change
user_invocable: true
last_reviewed_at: "2026-06-28"
---

# Authoring Rails Stylesheets

Use Sass/SCSS for Rails HTML styling. Class names describe product/UI meaning, not
visual accidents.

Read [[authoring-rails-views]] when adding markup.


## Rules

- Style with `.scss`/Sass files according to the project's asset structure.
- Use semantic class names based on the view/component concept.
- Prefer BEM-style shape:
  ```text
  .subscription-card
  .subscription-card__heading
  .subscription-card__status
  .subscription-card--cancelled
  ```
- Keep selectors shallow and stable.
- Do not style by incidental tag nesting when a semantic class is clearer.
- Do not put business state in CSS class names unless it comes from a presenter/view
  model as presentation state.
- Keep accessibility visible states: focus, disabled, error, selected, expanded.


## Avoid

- Inline styles in Slim templates.
- Random utility class soup unless the project has explicitly chosen that system.
- Classes named only for appearance, such as `.blue-box` or `.big-red-text`.
- Deep selectors coupled to fragile template structure.
- JavaScript hooks and styling hooks sharing the same class unless project convention
  requires it.
