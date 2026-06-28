---
name: authoring-rails-views
title: Authoring Rails Views
description: "Write Rails HTML views in Slim with semantic, accessible markup and no business logic. Use when adding or changing Rails templates, partials, page markup, form markup, or display branching; templates render view models through presenters, use I18n for end-user copy, and keep value finding out of the template."
category: authoring
status: active
version: 1.0
applies_to:
  - Ruby
  - Rails
  - Slim
  - HTML
priority: REQUIRED
triggers:
  - rails view
  - slim template
  - html template
  - partial
  - presenter
  - view model
  - accessible html
  - semantic html
anti_triggers:
  - JSON API only
  - mailer template only
user_invocable: true
last_reviewed_at: "2026-06-28"
---

# Authoring Rails Views

Rails HTML templates are rendering boundaries. They should be Slim, semantic,
accessible, translated, and free of business logic.

Read [[authoring-user-facing-copy]], [[authoring-view-models-and-presenters]],
[[authoring-presenters]], and [[authoring-stylesheets]] when the view includes copy,
presentation branching, or new CSS.


## Template Contract

Controllers expose view models to templates. Templates may wrap those view models in
presenters for the current view context.

```ruby
helper_method :account_summary

def show
end

private

def account_summary
  @account_summary ||= ViewModels::Accounts::Summary.new(account)
end
```

```slim
- presenter = present :account_summary, with: "Presenters::Accounts::SummaryPresenter"

article.account-profile
  h1.account-profile__heading = presenter.display_name
```


## Rules

- Use Slim for Rails templates and partials.
- Use semantic HTML first: headings in order, landmarks where useful, lists for lists,
  tables for tabular data, labels for form controls, buttons for actions.
- Keep a solid document outline; do not pick heading levels for visual size.
- Use accessible names for controls and links.
- All user-visible copy goes through `I18n.t`.
- No domain decisions, data fetching, permission checks, formatting branches, or object
  construction in templates.
- Use presenters for display branching and formatting. Use view models for view-ready
  data in model/domain language.
- Keep CSS classes semantic and stable; style with SCSS.


## Avoid

```slim
- if @subscription.cancelled? && @subscription.refund_due?
  p = "Refund pending"
```

The template is deciding domain/presentation state and hard-coding copy.

Prefer:

```slim
- presenter = present :subscription_summary, with: "Presenters::Billing::SubscriptionSummaryPresenter"

p.subscription-status = presenter.refund_status_text
```


## Stop And Ask

Ask before changing markup structure when accessibility, SEO, legal copy, or product
language is unclear.


## Completion Criteria

Done when the Slim template has semantic accessible markup, a coherent heading
outline, I18n-backed copy, stable semantic CSS classes, and no data fetching, object
construction, permission checks, or domain/display branching.
