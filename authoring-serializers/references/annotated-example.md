# Annotated Example — JSON:API Serializers

Neutral domain: a base serializer, a `ProfileSerializer`, and the error serializer.

## Base

```ruby
# frozen_string_literal: true

module V1
  class BaseSerializer
    include JSONAPI::Serializer

    # House convention: external id is the uuid when present, else id.
    set_id { |record| record.respond_to?(:uuid) ? record.uuid : record.id }

    # Always advertise the JSON:API version in the document.
    def serializable_hash
      super.merge(jsonapi: { version: '1.0' })
    end
  end
end
```

## Resource serializer

```ruby
# frozen_string_literal: true

module V1
  class ProfileSerializer < BaseSerializer
    # The includes a controller renders by default for this resource.
    STANDARD_INCLUDES = %i[identity].freeze

    set_type :profiles          # JSON:API type
    set_id(&:uuid)              # explicit uuid id for this resource

    # Only the attributes the API exposes — including a derived model accessor.
    attributes :first_name, :last_name, :phone, :full_name

    # Relationship linked by uuid, rendered by the related serializer.
    belongs_to :identity,
               serializer: IdentitySerializer,
               id_method_name: :uuid, &:identity
  end
end
```

## Error serializer

```ruby
# frozen_string_literal: true

module V1
  class ErrorSerializer
    # Controllers build these from form/model errors in failure callbacks.
    Error = Struct.new(:attribute, :message, :code, :title, keyword_init: true) do
      def full_message
        "#{attribute.to_s.humanize} #{message}"
      end
    end

    def self.form_validation_error(error:)
      {
        errors: [{
          status: '422',
          title: error_title_for(error.attribute),
          detail: error_detail_for(error),
          source: { pointer: error_pointer_for(error.attribute) },
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

    def self.unauthorized_error(detail: nil)
      {
        errors: [{
          status: '401',
          title: 'Unauthorized',
          detail: detail || 'The request requires valid authentication credentials.',
          source: { pointer: '/data' },
        }],
      }
    end

    def self.error_title_for(attribute)
      return 'Invalid Resource Type' if attribute == :type
      'Validation Error'
    end

    # Type mismatches use the dedicated helper so the ACTUAL expected type is
    # interpolated — never hard-code one resource's name in shared error code.
    def self.type_error(type:)
      {
        errors: [{
          status: '422',
          title: 'Invalid Resource Type',
          detail: I18n.t('v1.errors.resource_type.invalid', type: type),
          source: { pointer: '/data/type' },
        }],
      }
    end

    def self.error_detail_for(error)
      error.full_message
    end

    def self.error_pointer_for(attribute)
      case attribute
      when :type then '/data/type'
      else "/data/attributes/#{attribute}"
      end
    end
  end
end
```


## Why these choices

- **Shared base.** uuid-based ids and the `jsonapi` version are declared once; every
  serializer inherits them, so responses are uniform.
- **`set_type` + `set_id(&:uuid)`.** Explicit resource type and a public uuid identifier —
  internal `id` never leaks.
- **Curated `attributes`.** The serializer is the API contract; expose intended fields only,
  including derived accessors (`full_name`).
- **Relationships by uuid.** `id_method_name: :uuid` keeps linkage on public identifiers and
  delegates nested rendering to the related serializer.
- **`STANDARD_INCLUDES`.** Centralises the default `include` the controller passes to
  `render_json_api`, so callers don't repeat include lists.
- **No logic / no fetching.** The serializer presents already-loaded data; eager-load in the
  query object to avoid N+1s.
- **One error vocabulary.** Every failure response is `{ errors: [{ status, title, detail,
  source }] }` with conventional pointers (`/data/attributes/<attr>`, `/data/type`,
  `/data`, `/data/id`); the `Error` struct is the bridge from form/model errors to the
  document.
