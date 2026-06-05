---
name: authoring-form-objects
title: Authoring Form Objects
description: How to write a form object - an ActiveModel::Model class that validates incoming params, curates error messages, duck-types as a model, and builds the domain objects a use case will persist. Use when adding or changing classes under app/lib/forms.
category: architecture
status: active
version: 1.1
applies_to:
  - Ruby
  - Rails
  - ActiveModel
priority: REQUIRED
triggers:
  - write a form object
  - new form class
  - Forms class
  - validate params before a use case
anti_triggers:
  - use case (persistence)
  - user story
  - query object
user_invocable: true
last_reviewed_at: 2026-06-03
---


# Authoring Form Objects

A form object is an `ActiveModel::Model` that **validates incoming params and builds the
domain objects** a use case will persist. It is the validation boundary: a use case takes a
form (`required :form`) and trusts `valid?`.


## Required Reading

None beyond this collection. (When the project uses the layers gem, the derisk_layers
collection's placement skill adds layer guidance.)

Supporting references in this skill:

```text
references/annotated-example.md   # a full form object, annotated
references/checklist.md           # authoring checklist
```

Consumed by the persisting caller (a use case, when using the layers gem); test it with
[[testing-form-objects]].


## Placement and Naming

```text
app/lib/forms/<domain>/<action>_form.rb  →  Forms::<Domain>::<Action>Form
```

Engines/APIs carry their own `app/lib/forms/...` (e.g. `Forms::V1::ProfileUpdate`).


## Anatomy

Every form has the same members, in this order:

1. `include ActiveModel::Model`.
2. `attr_writer` for internals (`:persisted`); `attr_accessor` for the inputs (one per line,
   continuation style, when there are several).
3. `validates` / `validate` for the rules the form owns; messages via `I18n.t`.
4. `form_error_messages` — the curated error reader, filtering through a private
   `report_full_errors_for` whitelist. Every form provides it; it is how controllers and
   serializers surface errors.
5. Builder methods that construct (not persist) the domain objects, memoized.
6. Model duck typing: `new_record?` / `persisted?`. Create-style forms use
   `attr_writer :persisted` with `@persisted ||= false`; update-style forms return the
   wrapped record's semantics (`persisted?` → `true`).
7. Private: `report_full_errors_for`, custom validators, memoized look-ups.

```ruby
module Forms
  module Orders
    class CreateForm
      include ActiveModel::Model

      attr_writer :persisted
      attr_accessor :customer_name,
                    :line_items_attributes

      validates :customer_name, presence: true
      validate :line_item_products_exist


      def form_error_messages
        errors.select do |error|
          report_full_errors_for.include? error.attribute
        end.map(&:full_message).compact.reject(&:empty?)
      end


      def order
        @order ||= Order.new(customer_name: customer_name)
      end

      def line_items
        return [] if line_items_attributes.blank?

        @line_items ||= line_items_attributes.map do |attrs|
          LineItem.new(order: order, product_id: product_id_for(attrs[:sku]))
        end
      end


      def new_record?
        !persisted?
      end

      def persisted?
        @persisted ||= false
      end


      private

      def report_full_errors_for
        %i[
          customer_name
          line_items
        ]
      end

      def line_item_products_exist
        return if line_items_attributes.blank?

        line_items_attributes.each do |attrs|
          next if product_id_for(attrs[:sku])
          errors.add(:line_items, I18n.t('orders.validation.product_not_found', sku: attrs[:sku]))
        end
      end

      def product_id_for(sku)
        return nil unless sku
        @product_ids ||= {}
        @product_ids[sku] ||= Product.find_by(sku: sku)&.id
      end
    end
  end
end
```


## Rules

- The form **builds**, it does not **save**. Persistence is the use case's job inside a
  transaction.
- All validation lives here, not in the controller or the use case.
- Every form exposes `form_error_messages` filtered through `report_full_errors_for` —
  only user-relevant attributes surface.
- Every form duck-types as a model: `valid?`, `errors`, `new_record?`, `persisted?`.
- Look-ups needed for validation/construction are memoized to avoid repeat queries.
- Messages come from `I18n.t`.


## Avoid

- calling `save`/`update` — persistence belongs to the caller (e.g. a use case).
- leaking raw params into the use case unvalidated.
- duplicating model validations the form does not own; validate what the *form* is
  responsible for (cross-field rules, existence of referenced records, payload shape).
- hard-coded error message strings — use `I18n.t`.
