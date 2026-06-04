# common_agent_skills/derisk_rails/testing-routing/references/annotated-example.md


# Annotated Example — Routing Specs

Neutral domain: an `articles` resource exposing only index/show plus a publish action,
and a standalone dashboard route. The spec covers **all four quadrants**: resourceful and
non-resourceful, each with permitted and blocked routes. An engine variant and the
engine-mounting spec follow.


## App Routes — Four Quadrants

```ruby
# frozen_string_literal: true

require 'rails_helper'

# Routes (copied from config/routes.rb so the spec documents intent)
#
#   resources :articles, only: %i[index show], param: :uuid do
#     member { post :publish }
#   end
#
#   get 'dashboard' => 'dashboards#show', as: :dashboard
#   get 'up' => 'rails/health#show', as: :rails_health_check

RSpec.describe ArticlesController, type: :routing do
  # The one helper a routing spec carries: the controller string builder.
  def articles_controller(action)
    "articles##{action}"
  end


  describe 'Resourceful Routes' do
    # Default Rails resource routes the app DOES expose.
    context 'permitted' do
      specify '#index for GET /articles' do
        expect(get: '/articles').to route_to(articles_controller('index'))
      end

      # Captured params are asserted as matcher options. Public routes capture
      # uuid — never :id (param: :uuid in routes.rb).
      specify '#show for GET /articles/:uuid' do
        expect(get: '/articles/abc-123').to route_to(
          articles_controller('show'),
          uuid: 'abc-123',
        )
      end

      # Member routes declared inside the resources block are resourceful too.
      specify '#publish for POST /articles/:uuid/publish' do
        expect(post: '/articles/abc-123/publish').to route_to(
          articles_controller('publish'),
          uuid: 'abc-123',
        )
      end
    end

    # Default Rails resource routes that only: %i[index show] must EXCLUDE.
    context 'not permitted' do
      specify '#new for GET /articles/new' do
        expect(get: '/articles/new').not_to be_routable
      end

      specify '#create for POST /articles' do
        expect(post: '/articles').not_to be_routable
      end

      specify '#edit for GET /articles/:uuid/edit' do
        expect(get: '/articles/abc-123/edit').not_to be_routable
      end

      specify '#update for PATCH /articles/:uuid' do
        expect(patch: '/articles/abc-123').not_to be_routable
      end

      specify '#destroy for DELETE /articles/:uuid' do
        expect(delete: '/articles/abc-123').not_to be_routable
      end
    end
  end
end


RSpec.describe DashboardsController, type: :routing do
  describe 'Non-Resourceful Routes' do
    # Standalone routes declared with get/post/etc. outside resources blocks.
    context 'permitted' do
      specify '#show for GET /dashboard' do
        expect(get: '/dashboard').to route_to('dashboards#show')
      end
    end

    # The standalone route exposes exactly one verb; the others must not exist.
    context 'not permitted' do
      specify 'POST /dashboard' do
        expect(post: '/dashboard').not_to be_routable
      end

      specify 'DELETE /dashboard' do
        expect(delete: '/dashboard').not_to be_routable
      end
    end
  end
end
```


## Engine Routes

Engine routing specs declare the engine's route set; paths are relative to the mount.
Nested resources capture `<resource>_uuid` params:

```ruby
# frozen_string_literal: true

require 'rails_helper'

RSpec.describe V1::TodoItemsController, type: :routing do
  routes { V1::Engine.routes }

  def todo_items_controller(action)
    "v1/todo_items##{action}"
  end

  describe 'Resourceful Routes' do
    context 'permitted' do
      specify '#show for GET /engagements/:engagement_uuid/todo_items/:uuid' do
        expect(get: '/engagements/abc-123/todo_items/def-456').to route_to(
          todo_items_controller('show'),
          engagement_uuid: 'abc-123',
          uuid: 'def-456',
        )
      end
    end

    context 'not permitted' do
      specify '#edit for GET /engagements/:engagement_uuid/todo_items/:uuid/edit' do
        expect(get: '/engagements/abc-123/todo_items/def-456/edit').not_to be_routable
      end
    end
  end
end
```


## Engine Mounting Spec

Each mounted engine gets one spec pinning where the host app mounts it:

```ruby
# frozen_string_literal: true

require 'rails_helper'

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


## Why these choices

- **Four quadrants.** Resourceful and non-resourceful routes each get `permitted` and
  `not permitted` contexts. A routing spec's value is pinning the surface area exactly —
  what exists AND what must not; `only:`/`except:` restrictions are only proven by the
  blocked side.
- **Route comment up top.** The spec doubles as documentation of the intended routing
  table; copying from `routes.rb` makes drift obvious.
- **`specify '#action for VERB /path'`.** The example name carries the whole mapping;
  the matcher proves it.
- **uuid params.** `param: :uuid` (and nested `<resource>_uuid`) keep numeric ids off the
  public surface; asserting the captured params pins that.
- **The controller-string helper.** `articles_controller('show')` is the one helper a
  routing spec carries — it keeps namespaced controller strings in one place.
- **`not_to be_routable`** is the clean way to prove a verb+path has no route.
- **Engine mounting pinned separately.** The engine's internal table and its mount point
  in the host are two different facts; each gets its own spec.
