# common_agent_skills/derisk_rails/testing-form-objects/references/annotated-example.md


# Annotated Example — Form Object Spec

Neutral domain: `Forms::Orders::CreateForm` — validates order params and builds the order plus
its line items.


## The Object Under Test

The form being specced, compact. The fully annotated version of this object is the
annotated example in [[authoring-form-objects]] — each spec section below maps onto one of
its members.

```ruby
# frozen_string_literal: true

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

How the spec maps to the object:

| Spec section               | Form member(s)                                      |
| -------------------------- | --------------------------------------------------- |
| `Attributes`               | `attr_accessor` inputs + builder readers            |
| `Form Duck Typing`         | `errors` / `new_record?` / `persisted?` / `valid?`  |
| `Validations`              | `validates` / `validate :line_item_products_exist`  |
| `#order`, `#line_items`    | the builder methods                                 |
| `#form_error_messages`     | the curated error reader + its whitelist            |


## The Spec

```ruby
# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Forms::Orders::CreateForm do
  include Shoulda::Matchers::ActiveModel

  # Form objects are plain ActiveModel::Model: build with **params, vary one input per context.
  subject(:form) { described_class.new(**params) }

  let(:params) { valid_params }
  let(:valid_params) do
    { customer_name: 'Ada Lovelace', line_items_attributes: [] }
  end


  # --- The attribute contract ------------------------------------------------
  # Each declared input and each builder reader, pinned with one-liners.
  describe 'Attributes' do
    it { is_expected.to respond_to(:customer_name) }
    it { is_expected.to respond_to(:line_items_attributes) }

    it { is_expected.to respond_to(:order) }
    it { is_expected.to respond_to(:line_items) }
  end


  # --- Form duck typing --------------------------------------------------------
  # The form stands in for an AR model in controllers/views; pin the duck type.
  describe 'Form Duck Typing' do
    it { is_expected.to respond_to(:errors) }
    it { is_expected.to respond_to(:new_record?) }
    it { is_expected.to respond_to(:persisted?) }
    it { is_expected.to respond_to(:valid?) }
  end


  # --- Validity under varying params ----------------------------------------
  describe 'Validations' do
    # Simple rules: shoulda-matchers one-liners.
    it { is_expected.to validate_presence_of(:customer_name) }

    # Validity alone is self-contained — no execute needed.
    context 'with a blank customer name' do
      let(:params) { valid_params.merge(customer_name: nil) }

      it { is_expected.not_to be_valid }
    end

    # Asserting form.errors reads the AFTERMATH of valid? — execute is mandatory.
    context 'with a line item for a missing product' do
      let(:params) do
        valid_params.merge(line_items_attributes: [{ sku: 'does-not-exist' }])
      end

      execute do
        form.valid?
      end

      it { is_expected.not_to be_valid }

      it 'adds an error message' do
        expect(form.errors[:line_items]).to include('Product does-not-exist not found')
      end
    end
  end


  # --- The objects the form builds ------------------------------------------
  # Builders are pure incoming queries: the expectation wraps the call directly.
  describe '#order' do
    it 'returns a new order with the customer name' do
      expect(form.order.customer_name).to eq('Ada Lovelace')
    end
  end

  describe '#line_items' do
    context 'with no line_items_attributes' do
      it 'returns an empty array' do
        expect(form.line_items).to eq([])
      end
    end

    context 'with a valid line item' do
      let(:product) { FactoryBot.create(:product, sku: 'SKU-1') }
      let(:params)  { valid_params.merge(line_items_attributes: [{ sku: product.sku }]) }

      # Independent facts → separate examples (do not stack expectations).
      it 'builds a line item' do
        expect(form.line_items.first).to be_a(LineItem)
      end

      it 'links the line item to the product' do
        expect(form.line_items.first.product_id).to eq(product.id)
      end
    end
  end


  # --- Curated errors ----------------------------------------------------------
  # form_error_messages reads errors populated by valid? — execute is mandatory.
  describe '#form_error_messages' do
    execute do
      form.valid?
    end

    context 'when there are no errors' do
      it 'returns an empty array' do
        expect(form.form_error_messages).to eq([])
      end
    end

    context 'when there are errors' do
      let(:params) { valid_params.merge(customer_name: nil) }

      it 'returns formatted error messages' do
        expect(form.form_error_messages).to include("Customer name can't be blank")
      end
    end
  end
end
```


## Why these choices

- **`subject(:form)` + `params`/`valid_params`.** Identical override discipline to use-case
  specs: change one input per context. Individual lets per attribute are an acceptable
  variant when the form takes a handful of named attributes.
- **Attributes + Form Duck Typing sections.** The form's public surface and its AR-model
  stand-in contract are pinned with cheap one-liners before any behaviour is tested.
- **Shoulda one-liners for simple rules; contexts for the rest.** `validate_presence_of`
  states the rule exactly; payload-shape and existence rules need a context.
- **`execute { form.valid? }` whenever an example reads the aftermath.** `form.errors` and
  `#form_error_messages` are only populated after `valid?` runs; `execute` guarantees it.
  Validity one-liners are self-contained and skip it.
- **Builder methods get their own `describe '#method'`.** A form's job is to *construct*
  domain objects; assert the constructed object's attributes.
- **No persistence assertions.** Forms build; the caller (e.g. a use case) persists, and
  its specs cover that. Asserting `save`/DB state here tests the wrong layer.
- **One expectation per `it`.** "builds a line item" and "links the product" are separate.
