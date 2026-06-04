# common_agent_skills/derisk_rails/testing-rails-requests/references/shared-infrastructure.md


# Building the Shared Contexts and Shared Examples

The request-spec discipline depends on shared infrastructure under `spec/support/`
(loaded by the `rails_helper` support glob). This reference shows how to build each
piece in a fresh app.

```text
spec/support/
├── shared_contexts/
│   └── with_api_authentication.rb
└── shared_examples/
    ├── an_authenticated_route.rb
    ├── a_public_route.rb
    ├── requires_authentication.rb
    └── handles_not_found_error.rb
```


## The Key Mechanic

Shared examples compose with the **host spec's lets**: they reference `path` (and
sometimes override `headers`) and rely on RSpec's lazy resolution — the host defines
`let(:path)`, the shared example supplies its own `execute` and assertions. That is why
each shared example documents which lets it expects.


## The Shared Context: `with api authentication`

Builds a real authenticated principal (identity → user account → OAuth token, here via
Doorkeeper) and exposes the headers every API spec needs:

```ruby
# frozen_string_literal: true

RSpec.shared_context 'with api authentication' do
  # The authenticated principal, available to host specs (e.g. for scoping fixtures).
  let(:authenticated_identity) { FactoryBot.create(:identity) }
  let(:authenticated_user_account) do
    FactoryBot.create(:user_account, identity: authenticated_identity)
  end

  # A real OAuth application + token — auth is exercised, not stubbed.
  let(:authenticated_application) do
    FactoryBot.create(:doorkeeper_application, name: 'Test App')
  end

  let(:access_token) do
    FactoryBot.create(
      :doorkeeper_access_token,
      application: authenticated_application,
      resource_owner_id: authenticated_user_account.uuid,
    )
  end

  # Content types, overridable per API flavour.
  let(:json_api_content_type) { {} }
  let(:graphql_content_type) { { 'Content-Type' => 'application/json' } }
  let(:content_type_header) { json_api_content_type }

  let(:request_headers) do
    { 'Accept' => 'application/vnd.api+json;version=v1' }.merge(content_type_header)
  end

  let(:graphql_request_headers) do
    {
      'Accept' => 'application/json',
      'Content-Type' => 'application/json',
    }
  end

  # The headers host specs actually use.
  let(:auth_headers) { { 'Authorization' => "Bearer #{access_token.token}" } }
  let(:authenticated_headers) { request_headers.merge(auth_headers) }
  let(:graphql_authenticated_headers) { graphql_request_headers.merge(auth_headers) }
end
```

Everything is a `let`, so host specs can override any layer (a different identity, an
extra header) without touching the context.


## `an authenticated route` (JSON:API)

The 401 trio — missing, invalid, and expired tokens — for any API endpoint. Expects a
`path` let from the host; headers come from the shared context:

```ruby
# frozen_string_literal: true

RSpec.shared_examples 'an authenticated route' do
  context 'without authentication' do
    execute do
      get path, headers: request_headers
    end

    it { expect(response).to have_http_status(:unauthorized) }

    it 'returns an unauthorized error' do
      expect(JSON.parse(response.body)['errors'].first['title']).to eq('Unauthorized')
    end
  end

  context 'with an invalid token' do
    let(:invalid_headers) do
      request_headers.merge('Authorization' => 'Bearer invalid_token')
    end

    execute do
      get path, headers: invalid_headers
    end

    it { expect(response).to have_http_status(:unauthorized) }
  end

  context 'with an expired token' do
    let(:expired_token) do
      FactoryBot.create(
        :doorkeeper_access_token,
        resource_owner_id: authenticated_user_account.uuid,
        expires_in: -1.day,
      )
    end

    let(:expired_headers) do
      request_headers.merge('Authorization' => "Bearer #{expired_token.token}")
    end

    execute do
      get path, headers: expired_headers
    end

    it { expect(response).to have_http_status(:unauthorized) }
  end
end
```

Host usage:

```ruby
include_context 'with api authentication'

let(:path) { '/api/articles' }

it_behaves_like 'an authenticated route'
```


## `a public route`

The inverse — pins that an endpoint stays open:

```ruby
# frozen_string_literal: true

RSpec.shared_examples 'a public route' do
  context 'without authorization' do
    let(:public_headers) do
      {
        'Accept' => 'application/vnd.api+json;version=v1',
        'Content-Type' => 'application/vnd.api+json',
      }
    end

    execute do
      get path, headers: public_headers
    end

    it 'returns HTTP status 200' do
      expect(response).to have_http_status(:ok)
    end
  end
end
```


## `requires authentication` (header-override flavour)

Used where the host spec's own `execute` sends `headers:` from a `headers` let (the
GraphQL acceptance shape). The shared example only overrides that let — the host's
`execute` runs unauthenticated:

```ruby
# frozen_string_literal: true

RSpec.shared_examples 'requires authentication' do
  context 'without authentication' do
    let(:headers) { { 'Content-Type' => 'application/json' } }

    it 'returns an unauthorized error' do
      expect(JSON.parse(response.body)['errors'].first['title']).to eq('Unauthorized')
    end
  end
end
```

This is the leanest composition: no `execute` of its own — it reuses the host's, which
is why the host must route its verb's headers through `let(:headers)`.


## `handles not found error`

Parameterised by resource name; host specs point `path` at a non-existent uuid.
Overridable lets (`response_key`, `error_path`) cover endpoints whose payload key
differs from the resource name:

```ruby
# frozen_string_literal: true

RSpec.shared_examples 'handles not found error' do |resource_name|
  let(:expected_err_msg) { "#{resource_name} not found" }

  let(:parsed_response_errors) do
    JSON.parse(response.body)['errors']
  end

  it 'returns errors' do
    expect(parsed_response_errors).not_to be_empty
  end

  it 'returns a not found error' do
    expect(
      parsed_response_errors.any? { |e| e['message'] == expected_err_msg },
    ).to be(true)
  end
end
```

Host usage:

```ruby
context 'with an unknown article uuid' do
  let(:path) { '/api/articles/non-existent-uuid' }

  it_behaves_like 'handles not found error', 'Article'
end
```


## Why these choices

- **Real tokens, not stubs.** The context creates an actual OAuth application and token,
  so auth middleware is exercised end-to-end — the 401 trio would be meaningless against
  a stubbed authenticator.
- **Everything is a `let`.** Hosts override one layer (a different token, an extra
  header, another identity) without rebuilding the context.
- **Shared examples own their assertions, borrow the host's nouns.** `path` (and
  `headers` in the override flavour) are the documented seams; keep them stable.
- **One shared example per route posture.** `an authenticated route` /
  `a public route` make the spec's first line state the endpoint's security posture —
  every endpoint spec should carry one of them.
