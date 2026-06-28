---
name: testing-rails-requests
title: Testing Rails Request Specs
description: Spec pattern for Rails request specs driving HTTP endpoints - HTML/session endpoints (response, session, flash, redirects) and JSON:API endpoints (document params, auth headers, whole-shape assertions). Use when writing or modifying specs under spec/requests.
category: testing
status: active
version: 1.1
applies_to:
  - Ruby
  - Rails
  - RSpec
  - always_execute
  - JSON:API
priority: REQUIRED
triggers:
  - request spec
  - controller endpoint spec
  - http get post patch delete spec
  - assert response status redirect flash session
  - json api request spec
anti_triggers:
  - use case spec
  - model spec
  - graphql acceptance spec
user_invocable: true
last_reviewed_at: 2026-06-03
---


# Testing Rails Request Specs

Use this skill for request specs (`type: :request`) that exercise real HTTP endpoints
end-to-end through the router, controller, and views/serializers. Two flavours share one
discipline: **HTML/session endpoints** assert on session, flash, redirects, and templates;
**JSON:API endpoints** assert on status and the parsed response document.


## Required Reading

```text
[[ruby-testing]]
[[always-execute-rspec]]
```

Supporting references in this skill:

```text
references/annotated-example.md       # full HTML and JSON:API request specs, annotated
references/shared-infrastructure.md   # building the shared contexts/examples these specs rely on
references/checklist.md               # pre-merge review checklist
```

GraphQL endpoints have their own acceptance pattern (the derisk_layers collection's
testing-graphql, when using the layers gem).


## Shape (both flavours)

- `require 'rails_helper'` and `RSpec.describe 'Some Feature', type: :request`.
- One `describe 'VERB /path'` per endpoint/path.
- The HTTP verb is the action under test — it goes in `execute`.
- Build data with `FactoryBot`; request params in `let`s.
- Engine routes via their proxies (`auth.login_path`, `collab.feed_path`).

```ruby
describe 'POST /auth/login' do
  let(:identity) { FactoryBot.create(:identity) }

  context 'with valid credentials' do
    let(:valid_params) { { email: identity.email, password: 'Password123!' } }

    execute do
      post auth.sessions_path, params: valid_params
    end

    it 'redirects to the feed' do
      expect(response).to redirect_to(collab.feed_path)
    end
  end
end
```


## HTML / Session Endpoints

Assert on the HTTP-level effects, one per `it`:

- `expect(response).to have_http_status(:ok | :created | :unprocessable_content ...)`
- `expect(response).to redirect_to(...)` / `expect(response).to render_template(:new)`
- `expect(session[:key]).to be_present / be_nil`
- `expect(flash[:notice]).to eq(I18n.t('...'))` (use `flash.now[...]` when the controller
  sets it for the current render)

Prefer `I18n.t('...')` over hard-coded message strings.


## JSON:API Endpoints

API request specs send a JSON:API document as a raw JSON body with auth headers, address
records by `uuid` in paths, and assert the **whole** response shape:

```ruby
describe 'POST /api/articles' do
  include_context 'with api authentication'

  let(:author) { FactoryBot.create(:identity) }

  let(:valid_params) do
    {
      data: {
        type: 'articles',
        attributes: {
          title: 'Hello World',
        },
        relationships: {
          author: {
            data: { type: 'identities', id: author.uuid },
          },
        },
      },
    }
  end

  let(:path) { '/api/articles' }
  let(:parsed_response) { JSON.parse(response.body) }


  context 'with valid parameters' do
    execute do
      post path, params: valid_params.to_json, headers: authenticated_headers
    end

    # The created record, fetched once for the expected shape.
    let(:article) { Article.last }

    let(:expected_response) do
      {
        'data' => {
          'id' => article.uuid,                      # uuid is the public identifier
          'type' => 'articles',
          'attributes' => {
            'title' => 'Hello World',
            'status' => 'draft',
          },
        },
      }
    end

    it 'returns created' do
      expect(response).to have_http_status(:created)
    end

    it 'returns the expected response data' do
      expect(parsed_response).to eq(expected_response)
    end
  end
end
```

- Params go up as `valid_params.to_json` with `headers: authenticated_headers`.
- Define `parsed_response` as a `let` at the describe level.
- Records are addressed by `uuid` in paths and document ids — never `id`.
- For reads and creates, prefer one whole-shape `eq(expected_response)` (including
  `included` resources when the serializer side-loads them).


## Shared Contexts and Examples

```ruby
include_context 'with api authentication'   # authenticated_identity / authenticated_headers

it_behaves_like 'an authenticated route'    # API: 401s for missing/invalid/expired tokens
                                            # (expects a `path` let; headers come from the
                                            # shared context)
it_behaves_like 'a public route'            # the inverse
it_behaves_like 'handles not found error', 'article'  # 404 JSON:API error for unknown uuid
```

Protected HTML routes assert their redirect-to-login behaviour explicitly.

If the suite does not yet have these, build them first — `references/shared-infrastructure.md`
contains the full annotated implementations. Every endpoint spec should state its security
posture via one of the route shared examples.


## Deep Contexts Are Encouraged

When an endpoint's outcome depends on several params, **nest a context per variable** —
each level overrides exactly one `let`, and the tree enumerates the combinations that
matter. Depth is not a smell here; it mirrors the endpoint's decision tree, and the
nested descriptions read as a truth table:

```ruby
describe 'POST /api/articles' do
  context 'with an authenticated user' do
    context 'with a valid title' do
      context 'with a publish_at in the future' do
        let(:publish_at) { 1.week.from_now }

        it 'returns created' do
          expect(response).to have_http_status(:created)
        end
      end

      context 'with a publish_at in the past' do
        let(:publish_at) { 1.week.ago }

        it 'returns unprocessable content' do
          expect(response).to have_http_status(:unprocessable_content)
        end
      end
    end
  end
end
```

Ignore generic "avoid deep nesting" advice: do NOT flatten distinct input combinations
into fewer examples, stack expectations to save levels, or skip combinations that change
the outcome. Every combination that produces a different observable result gets its own
context and its own examples.


## Record-Count and Error Changes

When asserting a side effect that requires wrapping the action (count change, raise), use a
block matcher and call the verb inside the expectation (the delta-assertion exception in
always-execute-rspec):

```ruby
it 'creates an article record' do
  expect { post path, params: valid_params.to_json, headers: authenticated_headers }
    .to change(Article, :count).by(1)
end
```

Otherwise keep the verb in `execute` and assert on the response.


## Avoid

- multiple expectations per `it`; setup or the HTTP verb inside an `it` (except block matchers).
- asserting on internal implementation instead of the observable HTTP response.
- exposing or asserting numeric `id`s in API paths or documents — `uuid` is the public
  identifier.


## Preferred Structure

```ruby
# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Authentication', type: :request do
  describe 'GET /auth/login' do
    execute do
      get auth.login_path
    end

    it 'returns a successful response' do
      expect(response).to have_http_status(:success)
    end
  end


  describe 'POST /auth/login' do
    let(:identity) { FactoryBot.create(:identity) }

    context 'with invalid credentials' do
      let(:invalid_params) { { email: identity.email, password: 'wrong' } }

      execute do
        post auth.sessions_path, params: invalid_params
      end

      it 'does not set the user account id in session' do
        expect(session[:user_account_id]).to be_nil
      end

      it 'renders the new template' do
        expect(response).to render_template(:new)
      end

      it 'sets an error message' do
        expect(flash.now[:alert]).to eq(I18n.t('auth.login.failure'))
      end
    end
  end
end
```
