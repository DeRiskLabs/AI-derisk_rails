---
name: testing-routing
title: Testing Routes
description: Spec pattern for Rails routing specs that assert paths map to the intended controller actions and that disallowed routes do not exist - resourceful and non-resourceful, app and engine routes, plus engine mounting specs. Use when writing or modifying specs under spec/routing.
category: testing
status: active
version: 1.1
applies_to:
  - Ruby
  - Rails
  - RSpec
priority: REQUIRED
triggers:
  - routing spec
  - route_to spec
  - assert routes
  - engine mounting spec
anti_triggers:
  - request spec
  - controller behaviour spec
user_invocable: true
last_reviewed_at: 2026-06-03
---


# Testing Routes

Use this skill for `type: :routing` specs. They assert the router maps a path+verb to the
intended controller action — and, just as importantly, that routes which must NOT exist
are absent. They do not exercise controllers — that is [[testing-rails-requests]].


## Required Reading

```text
common_agent_skills/derisk_ruby/ruby-testing/SKILL.md
```

Supporting references in this skill:

```text
references/annotated-example.md   # resourceful + non-resourceful, permitted + blocked, engines
references/checklist.md           # review checklist
```


## Shape

- `require 'rails_helper'`, `RSpec.describe TheController, type: :routing` — describe the
  controller class (or the engine class for mounting specs).
- For engine routes, declare the route set: `routes { V1::Engine.routes }`; paths are then
  relative to the engine mount.
- A comment block near the top showing the route(s) under test, copied from `routes.rb`.
- Group with `describe 'Resourceful Routes'` / `describe 'Non-Resourceful Routes'`, then
  `context 'permitted'` / `context 'not permitted'` inside each.
- Name examples `specify '#action for VERB /path'`.
- A small helper for the controller string keeps the assertions readable:

```ruby
RSpec.describe V1::ArticlesController, type: :routing do
  routes { V1::Engine.routes }

  def articles_controller(action)
    "v1/articles##{action}"
  end

  describe 'Resourceful Routes' do
    context 'permitted' do
      specify '#show for GET /articles/:uuid' do
        expect(get: '/articles/abc-123').to route_to(
          articles_controller('show'),
          uuid: 'abc-123',
        )
      end
    end
  end
end
```


## Params Are uuids

Public routes capture `uuid` (and `<resource>_uuid` for nesting) — never `:id` — per the
public-API identifier rule. Assert the captured params explicitly:

```ruby
specify '#show for GET /engagements/:engagement_uuid/todo_items/:uuid' do
  expect(get: '/engagements/abc-123/todo_items/def-456').to route_to(
    todo_items_controller('show'),
    engagement_uuid: 'abc-123',
    uuid: 'def-456',
  )
end
```


## Permitted and Not Permitted

A routing spec's real value is pinning the surface area exactly — in **both** route
groups, assert what exists and what must not:

```ruby
context 'not permitted' do
  specify '#edit for GET /articles/:uuid/edit' do
    expect(get: '/articles/abc-123/edit').not_to be_routable
  end

  specify '#destroy for DELETE /articles/:uuid' do
    expect(delete: '/articles/abc-123').not_to be_routable
  end
end
```


## Engine Mounting Specs

Each mounted engine gets a spec pinning its mount point in the host app:

```ruby
RSpec.describe V1::Engine, type: :routing do
  routes { V1::Engine.routes }

  describe 'Mounting path' do
    let(:expected_mount_path) { '/api' }

    let(:actual_mount_path) do
      Rails.application.routes.routes.find do |route|
        route.app.app == V1::Engine
      end.path.spec.to_s
    end

    it 'is mounted at /api in the main app' do
      expect(actual_mount_path).to eq(expected_mount_path)
    end
  end
end
```


## Avoid

- multiple expectations per `it`/`specify`.
- re-testing controller behaviour here (use a request spec).
- `:id` params on public routes — uuids are the public identifiers.
- covering only the permitted side — blocked routes are half the contract.


## Preferred Structure

```ruby
# frozen_string_literal: true

require 'rails_helper'

# Routes
#
#   resources :articles, only: %i[index show], param: :uuid

RSpec.describe ArticlesController, type: :routing do
  def articles_controller(action)
    "articles##{action}"
  end

  describe 'Resourceful Routes' do
    context 'permitted' do
      specify '#index for GET /articles' do
        expect(get: '/articles').to route_to(articles_controller('index'))
      end

      specify '#show for GET /articles/:uuid' do
        expect(get: '/articles/abc-123').to route_to(
          articles_controller('show'),
          uuid: 'abc-123',
        )
      end
    end

    context 'not permitted' do
      specify '#destroy for DELETE /articles/:uuid' do
        expect(delete: '/articles/abc-123').not_to be_routable
      end
    end
  end
end
```
