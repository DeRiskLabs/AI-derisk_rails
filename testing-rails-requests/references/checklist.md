# common_agent_skills/derisk_rails/testing-rails-requests/references/checklist.md


# Review Checklist — Request Specs


## Structure

- [ ] `require 'rails_helper'` and `type: :request`.
- [ ] One `describe 'VERB /path'` per endpoint.
- [ ] HTTP verb is in a single `execute` (or in a block matcher for count/raise assertions).
- [ ] Data built with FactoryBot; request params in `let`s.
- [ ] Engine routes via their proxies (`auth.login_path`).


## HTML / session assertions (one per `it`)

- [ ] Status via `have_http_status(:symbol)`.
- [ ] Redirects via `redirect_to`; renders via `render_template`.
- [ ] Session effects via `session[:key]`.
- [ ] Flash via `flash[:notice]` (redirect) or `flash.now[:alert]` (render).
- [ ] Messages compared against `I18n.t('...')`, not literals.


## JSON:API assertions

- [ ] Body sent as `valid_params.to_json` with `headers: authenticated_headers`.
- [ ] Params are a JSON:API document (`data` / `type` / `attributes` / `relationships`).
- [ ] `parsed_response` defined as a `let` at the describe level.
- [ ] Paths and document ids use `uuid` — the numeric `id` never appears.
- [ ] Reads/creates assert the whole shape via `eq(expected_response)` (incl. `included`).
- [ ] Failure cases assert status + the JSON:API `errors` array.


## Coverage

- [ ] Happy path and at least one failure path per mutating endpoint.
- [ ] Every param combination that changes the outcome has its own (nested) context —
      one variable overridden per level; combinations never flattened into one example.
- [ ] API auth via `include_context 'with api authentication'` +
      `it_behaves_like 'an authenticated route'` (provide a `path` let; the shared context
      supplies the headers).
- [ ] Public endpoints pinned with `it_behaves_like 'a public route'` where relevant.
- [ ] Unknown-uuid behaviour via `it_behaves_like 'handles not found error', '<resource>'`.


## Avoid

- [ ] No verb or setup inside an `it` (block matchers excepted).
- [ ] No assertions on controller internals when an HTTP-level assertion is available.
- [ ] No numeric `id`s exposed in API paths or response assertions.
