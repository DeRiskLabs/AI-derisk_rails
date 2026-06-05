---
name: authoring-serializers
title: Authoring JSON:API Serializers
description: How to write JSON:API serializers (jsonapi-serializer) with a shared base, uuid ids, attributes, relationships, and standard includes. Use when adding or changing files under an apis/* engine's serializers.
category: architecture
status: active
version: 1.1
applies_to:
  - Ruby
  - Rails
  - JSON:API
  - jsonapi-serializer
priority: REQUIRED
triggers:
  - write a serializer
  - json api serializer
  - serialize a resource
anti_triggers:
  - controller logic
  - model logic
  - graphql type
user_invocable: true
last_reviewed_at: 2026-06-03
---


# Authoring JSON:API Serializers

Serializers turn domain objects into JSON:API responses. They are declarative: type, id,
attributes, relationships. A shared base sets house conventions (uuid ids, jsonapi version).


## Required Reading

None beyond this collection. (When the project uses the layers gem, the derisk_layers
collection's architecture hub explains where serializers sit in the layer map.)

Supporting references in this skill:

```text
references/annotated-example.md   # base + a resource serializer, annotated
references/checklist.md           # authoring checklist
```

Used by controllers; tested via [[testing-rails-requests]] (response shape).


## Placement

`apis/v1/app/serializers/v1/<resource>_serializer.rb`. A `V1::BaseSerializer` includes
`JSONAPI::Serializer`, sets the id from `uuid`, and merges the `jsonapi` version into the
hash. Concrete serializers inherit it.


## Anatomy

```ruby
module V1
  class ProfileSerializer < BaseSerializer
    STANDARD_INCLUDES = %i[identity].freeze   # default includes the controller passes

    set_type :profiles
    set_id(&:uuid)

    attributes :first_name, :last_name, :phone, :full_name

    belongs_to :identity,
               serializer: IdentitySerializer,
               id_method_name: :uuid, &:identity
  end
end
```


## The Error Serializer

Failure responses are JSON:API error documents, produced by one `ErrorSerializer` — the
error vocabulary the controllers' failure callbacks and `rescue_from` handlers consume:

```ruby
module V1
  class ErrorSerializer
    # The value object controllers build from form/model errors.
    Error = Struct.new(:attribute, :message, :code, :title, keyword_init: true) do
      def full_message
        "#{attribute.to_s.humanize} #{message}"
      end
    end

    def self.validation_error(error:)
      {
        errors: [{
          status: '422',
          title: 'Validation Error',
          detail: error.full_message,
          source: { pointer: "/data/attributes/#{error.attribute}" },
        }],
      }
    end

    def self.not_found_error(resource_type:)
      {
        errors: [{
          status: '404',
          title: 'Not Found',
          detail: "The requested #{resource_type} could not be found.",
          source: { pointer: '/data/id' },
        }],
      }
    end

    # plus: parameter_error, type_error, unauthorized_error,
    # multiple_validation_errors — same { status, title, detail, source } shape.
  end
end
```

Pointer conventions: attribute errors point at `/data/attributes/<attribute>`, type errors
at `/data/type`, payload errors at `/data`, missing records at `/data/id`. Every error
document is `{ errors: [{ status, title, detail, source }] }` — never a bespoke shape.


## Rules

- Inherit `BaseSerializer`; do not re-declare base conventions (uuid id, jsonapi version).
- `set_type` to the JSON:API resource type (plural); `set_id(&:uuid)`.
- Expose only intended `attributes` (including derived model accessors like `full_name`).
- Declare relationships with the related serializer and `id_method_name: :uuid` so linkage
  uses public identifiers.
- Provide a `STANDARD_INCLUDES` constant for the includes a controller renders by default.
- Error documents come from the one `ErrorSerializer`; interpolate the actual resource
  type into messages — never hard-code one resource's name in shared error helpers.
- No business logic; serializers only present already-loaded data.


## Avoid

- exposing internal `id` instead of `uuid`.
- computing or fetching data in the serializer (load it in the query/use case; avoid N+1).
- bespoke response envelopes — keep the JSON:API shape from the base.
