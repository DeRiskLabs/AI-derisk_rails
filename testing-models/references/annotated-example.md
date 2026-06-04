# common_agent_skills/derisk_rails/testing-models/references/annotated-example.md


# Annotated Example — Model Spec

Neutral domain: `Subscription`. The spec covers **everything the model file declares** —
and nothing the model does not.


## The Object Under Test

The model being specced, compact — a thin, doctrine-compliant model (fully annotated in
[[authoring-models]]). Each spec section below maps onto one of its declarations.

```ruby
# frozen_string_literal: true

class Subscription < ApplicationRecord
  resourcify

  belongs_to :account
  has_many :invoices, dependent: :destroy

  PERMITTED_STATUSES = %w[trial active cancelled].freeze

  validates :plan, presence: true
  validates :status, presence: true, inclusion: { in: PERMITTED_STATUSES }

  scope :active, -> { where(status: 'active') }
  scope :trial,  -> { where(status: 'trial') }

  before_validation :set_default_reference, on: :create

  def trial?
    status == 'trial'
  end


  private

  def set_default_reference
    self.reference = "SUB-#{SecureRandom.hex(4)}" if reference.blank?
  end
end
```

| Spec section                       | Model declaration                          |
| ---------------------------------- | ------------------------------------------ |
| `Associations`                     | `belongs_to` / `has_many`                  |
| `Validations`                      | `validates` + `PERMITTED_STATUSES`         |
| `Scopes`                           | `scope :active`, `scope :trial`            |
| `Callbacks`                        | `before_validation :set_default_reference` |
| `#trial?`                          | the intrinsic accessor                     |

Note what is NOT here: no `cancel!`/`activate!` specs, because transition methods are
state-machine logic and do not belong in the model (they are use cases, tested there).


## The Spec

```ruby
# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Subscription, type: :model do

  # One-liners pin what THIS model declares — not that Rails works.
  describe 'Associations' do
    it { is_expected.to belong_to(:account) }
    it { is_expected.to have_many(:invoices) }
  end


  describe 'Validations' do
    it { is_expected.to validate_presence_of(:plan) }
    it { is_expected.to validate_presence_of(:status) }

    # The state space, pinned against the model's own constant.
    it { is_expected.to validate_inclusion_of(:status).in_array(described_class::PERMITTED_STATUSES) }
  end


  describe 'Scopes' do
    # Scopes genuinely need the database: one matching and one non-matching record.
    describe '.active' do
      let!(:active_subscription) { FactoryBot.create(:subscription, :active) }

      before { FactoryBot.create(:subscription, :trial) }

      it 'returns only active subscriptions' do
        expect(described_class.active).to contain_exactly(active_subscription)
      end
    end

    describe '.trial' do
      let!(:trial_subscription) { FactoryBot.create(:subscription, :trial) }

      before { FactoryBot.create(:subscription, :active) }

      it 'returns only trial subscriptions' do
        expect(described_class.trial).to contain_exactly(trial_subscription)
      end
    end
  end


  describe 'Callbacks' do
    # Save-triggered callbacks genuinely need persistence — a necessary slow test.
    describe 'before_validation :set_default_reference' do
      subject(:subscription) { FactoryBot.build(:subscription, reference: nil) }

      # The triggering action goes in execute; assert the resulting state.
      execute do
        subscription.save!
      end

      it 'sets a default reference' do
        expect(subscription.reference).to be_present
      end
    end
  end


  describe '#trial?' do
    # Pure query — no persistence involved, so build, not create.
    subject(:subscription) { FactoryBot.build(:subscription, status: status) }

    context 'when the status is trial' do
      let(:status) { 'trial' }

      it { is_expected.to be_trial }
    end

    context 'when the status is active' do
      let(:status) { 'active' }

      it { is_expected.not_to be_trial }
    end
  end
end

# == Schema Information
# ... (annotaterb maintains this)
```


## Why these choices

- **Everything declared gets coverage.** Each association, validation, status constant,
  scope, callback, and public method in the model file appears in the spec — the spec
  documents what we told the model to do. The mapping table makes gaps visible.
- **Nothing undeclared gets tested.** No transition-method specs — a thin model has none;
  that behaviour (and its tests) live in use cases.
- **shoulda one-liners for structure.** Declarations are pinned at a glance without
  re-testing Rails; the inclusion matcher reads the model's own `PERMITTED_STATUSES`.
- **`build` vs `create`.** `build` (no DB hit) for validity and pure queries (`#trial?`);
  `create` only where persistence is the behaviour — scopes and save-triggered callbacks.
  Necessary slow tests are fine; unnecessary ones are waste.
- **Callbacks via `execute { save! }`.** The save triggers the callback once; the example
  asserts the resulting column.
- **Return values and deltas** (when a model has an intrinsic mutator like
  `request_verification!`) use `execute_result` and `change` block matchers — see the
  SKILL body's examples.
- **Schema footer left to annotaterb.** Never hand-edit it.
