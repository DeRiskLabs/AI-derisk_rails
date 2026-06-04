# common_agent_skills/derisk_rails/authoring-form-objects/references/annotated-example.md


# Annotated Example — Form Object

Neutral domain: `Forms::Orders::CreateForm` — validate order params and build the order plus
its line items. Annotated. The companion spec is the annotated example in
[[testing-form-objects]].

```ruby
# frozen_string_literal: true

module Forms
  module Orders
    class CreateForm
      include ActiveModel::Model          # gives valid?/errors + Rails form integration

      # attr_writer for internals; attr_accessor for inputs, one per line when several.
      attr_writer :persisted
      attr_accessor :customer_name,
                    :line_items_attributes

      validates :customer_name, presence: true
      validate :line_item_products_exist  # cross-field/existence rule the form owns


      # Curated errors: every form provides this reader, filtered through the
      # report_full_errors_for whitelist — only user-relevant attributes surface.
      def form_error_messages
        errors.select do |error|
          report_full_errors_for.include? error.attribute
        end.map(&:full_message).compact.reject(&:empty?)
      end


      # Builders construct, memoize, and DO NOT save.
      def order
        @order ||= Order.new(customer_name: customer_name)
      end

      def line_items
        return [] if line_items_attributes.blank?

        @line_items ||= line_items_attributes.map do |attrs|
          LineItem.new(order: order, product_id: product_id_for(attrs[:sku]))
        end
      end


      # Model duck typing. Create-style form: not persisted until a use case saves
      # and sets persisted = true. (Update-style forms return true instead.)
      def new_record?
        !persisted?
      end

      def persisted?
        @persisted ||= false
      end


      private

      # The whitelist behind form_error_messages.
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

      # Memoized look-up so validation + building don't double-query.
      def product_id_for(sku)
        return nil unless sku
        @product_ids ||= {}
        @product_ids[sku] ||= Product.find_by(sku: sku)&.id
      end
    end
  end
end
```


## Why these choices

- **`include ActiveModel::Model`** gives `valid?`, `errors`, and form integration without an
  AR table — the form is a pure boundary object.
- **`form_error_messages` + `report_full_errors_for` on every form.** Controllers and
  serializers consume errors through this one curated reader; internal errors stay out of
  the response. The implementation is identical across forms — keep it canonical.
- **Builders memoize and never save.** `order`/`line_items` return in-memory objects; a use
  case persists them in a transaction. This keeps "what to build" and "how to persist"
  separate.
- **Duck typing on every form.** Controllers and views treat the form as the model
  (`form_for`, `new_record?` branching); create-style forms start unpersisted, update-style
  forms report `persisted?` → `true`.
- **Existence validated here.** "product must exist" is the form's rule (it shapes the
  payload), so it lives in the form, not the model or controller.
- **Memoized look-ups.** `product_id_for` caches, so validating and building don't query
  twice.
- **Messages via `I18n.t`** — no hard-coded strings.
