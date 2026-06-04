# common_agent_skills/derisk_rails/authoring-models/references/annotated-example.md


# Annotated Example — Model

Neutral domain: `Subscription`. A thin model showing everything a model is allowed to
contain. The companion spec is the annotated example in [[testing-models]].

```ruby
# frozen_string_literal: true

class Subscription < ApplicationRecord
  # Declarative gem macros are fine (rolify/resourcify, etc.).
  resourcify # roles can be granted on subscriptions

  # Associations declare data shape.
  belongs_to :account
  has_many :invoices, dependent: :destroy

  # Status DECLARATION: the constant + inclusion validation pin the state space.
  # Transitions (cancel, activate) are state-machine logic — they live in use cases.
  PERMITTED_STATUSES = %w[trial active cancelled].freeze

  # Validations express data integrity.
  validates :plan, presence: true
  validates :status, presence: true, inclusion: { in: PERMITTED_STATUSES }

  # Simple scopes are fine. When they multiply or grow complex (joins, parameters,
  # raw SQL), extract a query object instead.
  scope :active, -> { where(status: 'active') }
  scope :trial,  -> { where(status: 'trial') }

  # Default setting is fine: intrinsic, local, runs once on create.
  before_validation :set_default_reference, on: :create

  # A small, intrinsic accessor — pure, local, no side effects. This is the ceiling for
  # model logic; anything more goes to a use case / form / query object.
  def trial?
    status == 'trial'
  end


  private

  def set_default_reference
    self.reference = "SUB-#{SecureRandom.hex(4)}" if reference.blank?
  end
end

# == Schema Information
#
# Table name: subscriptions
#
#  id         :bigint           not null, primary key   <- id stays the primary key
#  uuid       :uuid             not null                <- public-API identifier, additional
#  ... (annotaterb maintains this)
```


## Why these choices

- **Thin by design.** The model knows its shape (associations), its integrity rules
  (validations), its state space (the constant), and its own intrinsic facts (`trial?`).
  It does not transition state, update other records, send mail, or branch on workflow.
- **`PERMITTED_STATUSES` without transitions.** Declaring the legal states here gives one
  authoritative list (validations, specs, and UI option lists all read it). The moment a
  `cancel!` method appears, state-machine logic has leaked in — that is a use case.
- **Scopes with a budget.** Two one-line scopes document common reads. A scope taking
  parameters, joining tables, or accumulating siblings is a query object trying to happen.
- **`uuid` alongside `id`.** Anything that goes out on a public API carries a `uuid` as its
  external identifier — serializers and look-ups use it at the edges — while `id` remains
  the (internal) primary key. Factories populate `uuid` (see [[testing-factories]]).
- **Default setting, not side effects.** `set_default_reference` fills an intrinsic blank
  on the record itself. A callback that touched another object would belong in a use case.
- **Schema footer** is generated; treat it as read-only.
