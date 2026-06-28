# Presenter Testing

Presenter specs prove view-language branches and fallback behavior. They do not prove
the whole page renders.


## RSpec Presenter Spec

```ruby
# spec/presenters/billing/subscription_summary_presenter_spec.rb
require "rails_helper"

RSpec.describe Presenters::Billing::SubscriptionSummaryPresenter do
  include ActionView::TestCase::Behavior

  subject(:presenter) do
    described_class.new(subscription_summary, view)
  end

  let(:subscription_summary) do
    instance_double(
      ViewModels::Billing::SubscriptionSummary,
      status: "active",
      renews_on: Date.new(2026, 7, 1),
      cancellable?: true,
      uuid: "sub_123",
    )
  end

  before do
    allow(view).to receive(:billing_subscription_cancellation_path)
      .with("sub_123")
      .and_return("/billing/subscription/cancellation")
  end

  describe "#status_badge" do
    it "renders the translated status with the status class" do
      expect(presenter.status_badge).to include(I18n.t("billing.subscriptions.statuses.active"))
      expect(presenter.status_badge).to include("subscription-card__status--active")
    end
  end

  describe "#cancellation_action" do
    it "renders the cancellation link" do
      expect(presenter.cancellation_action).to include(I18n.t("billing.subscriptions.cancel"))
      expect(presenter.cancellation_action).to include("/billing/subscription/cancellation")
    end
  end
end
```


## Rendering Check

Add a request, system, or view-rendering spec for important pages:

```ruby
RSpec.describe "Billing subscription", type: :request do
  it "renders the subscription summary" do
    authenticate_user_according_to_project_convention

    get billing_subscription_path

    expect(response).to have_http_status(:ok)
    expect(response.body).to include(I18n.t("billing.subscriptions.statuses.active"))
  end
end
```


## Testing Rules

- Test presenter branches and fallbacks directly.
- Stub view helpers only when the helper is not the behavior under test.
- Compare copy against `I18n.t`, not hard-coded literals.
- Use a rendering-level spec for pages that matter.
- Do not re-test domain rules in presenter specs.
