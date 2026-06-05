# Annotated Examples — Request Specs

Two complete request specs, annotated: an HTML/session endpoint and a JSON:API endpoint.
Neutral domains: a sessions controller and an articles API.


## HTML / Session Endpoint

```ruby
# frozen_string_literal: true

require 'rails_helper'

# type: :request boots the full Rack stack: router → controller → views. We assert on the
# observable HTTP result (response/session/flash), not on controller internals.
RSpec.describe 'Sessions', type: :request do
  describe 'GET /login' do
    # The HTTP verb is the action under test → it goes in execute, runs once per example.
    execute do
      get '/login'
    end

    it 'returns a successful response' do
      expect(response).to have_http_status(:success)
    end
  end


  describe 'POST /sessions' do
    # Real data for the happy path.
    let(:user) { FactoryBot.create(:user, password: 'Password123!') }

    context 'with valid credentials' do
      let(:valid_params) { { email: user.email, password: 'Password123!' } }

      execute do
        post '/sessions', params: valid_params
      end

      it 'signs the user in' do
        expect(session[:user_id]).to eq(user.id)
      end

      it 'redirects to the dashboard' do
        expect(response).to redirect_to(dashboard_path)
      end

      it 'sets a success flash' do
        expect(flash[:notice]).to eq(I18n.t('sessions.create.success'))
      end
    end

    context 'with invalid credentials' do
      let(:invalid_params) { { email: user.email, password: 'wrong' } }

      execute do
        post '/sessions', params: invalid_params
      end

      it 'does not sign the user in' do
        expect(session[:user_id]).to be_nil
      end

      it 're-renders the new template' do
        expect(response).to render_template(:new)
      end

      # flash.now (not flash) — the controller renders, it does not redirect.
      it 'sets an error flash' do
        expect(flash.now[:alert]).to eq(I18n.t('sessions.create.failure'))
      end
    end

    # When the behaviour is a side-effect count, wrap the verb in a block matcher
    # (the delta-assertion exception in always-execute-rspec).
    context 'rate limiting' do
      it 'records a login attempt' do
        expect { post '/sessions', params: { email: user.email, password: 'wrong' } }
          .to change(LoginAttempt, :count).by(1)
      end
    end
  end
end
```


## JSON:API Endpoint

```ruby
# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'V1::Articles#create', type: :request do
  # Shared context provides authenticated_identity / authenticated_headers.
  include_context 'with api authentication'

  let(:author) { FactoryBot.create(:identity) }

  # The request body is a JSON:API document; related records are referenced by uuid.
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

  # The shared example exercises 401s for missing/invalid/expired tokens.
  # It expects a `path` let; the shared context supplies the headers.
  it_behaves_like 'an authenticated route'


  describe 'POST /api/articles' do
    context 'with valid parameters' do
      # Raw JSON body + auth headers — this is how API clients actually call.
      execute do
        post path, params: valid_params.to_json, headers: authenticated_headers
      end

      # The created record, fetched once for the expected shape.
      let(:article) { Article.last }

      # Whole-shape assertion: the entire serialized document is the contract.
      # uuid — never the numeric id — is the public identifier.
      let(:expected_response) do
        {
          'data' => {
            'id' => article.uuid,
            'type' => 'articles',
            'attributes' => {
              'title' => 'Hello World',
              'status' => 'draft',
            },
            'relationships' => {
              'author' => {
                'data' => { 'id' => author.uuid, 'type' => 'identities' },
              },
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

      it 'creates an article record' do
        expect { post path, params: valid_params.to_json, headers: authenticated_headers }
          .to change(Article, :count).by(1)
      end
    end

    context 'with an unknown author uuid' do
      let(:valid_params) do
        {
          data: {
            type: 'articles',
            attributes: { title: 'Hello World' },
            relationships: {
              author: { data: { type: 'identities', id: 'non-existent-uuid' } },
            },
          },
        }
      end

      execute do
        post path, params: valid_params.to_json, headers: authenticated_headers
      end

      it 'returns unprocessable content' do
        expect(response).to have_http_status(:unprocessable_content)
      end

      it 'returns a JSON:API error' do
        expect(parsed_response.fetch('errors').first['detail']).to be_present
      end
    end
  end
end
```


## Why these choices

- **One `describe 'VERB /path'` per endpoint.** Keeps each endpoint's contexts together.
- **Verb in `execute`.** The single request runs before each `it`; examples assert distinct
  facets (session, redirect, flash / status, document) of that one request.
- **`flash` vs `flash.now`.** Redirects set `flash`; renders set `flash.now`. Match the
  controller.
- **`I18n.t` over literals.** Asserting the translation key keeps specs stable across copy
  edits and matches the controller's source of truth.
- **JSON body + headers for APIs.** `valid_params.to_json` with `authenticated_headers` is
  what a real client sends; `parsed_response` is a local `let`.
- **Whole-shape `eq(expected_response)` for API reads/creates.** The serialized document is
  the contract — including `relationships` and any `included` resources.
- **uuid at the edges.** Paths and document ids use `uuid`; the numeric `id` never leaks.
- **Block matcher for counts.** `change(Model, :count)` wraps the action, so the verb
  appears inside the expectation — the delta-assertion exception in always-execute-rspec.
