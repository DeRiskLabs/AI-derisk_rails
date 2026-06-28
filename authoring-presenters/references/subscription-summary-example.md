# Subscription Summary Presenter Example

This is a complete small slice showing the intended relationship:

```text
controller -> view model -> presenter -> Slim template
```

The controller exposes a memoized view model. The template presents that view model
with an explicit presenter class. The presenter speaks view language. The view model
speaks subscription language.


## Controller

```ruby
# app/controllers/billing/subscriptions_controller.rb
module Billing
  class SubscriptionsController < ApplicationController
    helper_method :subscription_summary

    def show
    end


    private

    def subscription_summary
      @subscription_summary ||= ViewModels::Billing::SubscriptionSummary.new(subscription)
    end

    def subscription
      @subscription ||= current_account.subscription
    end
  end
end
```


## View Model

```ruby
# app/lib/view_models/billing/subscription_summary.rb
module ViewModels
  module Billing
    class SubscriptionSummary
      attr_reader :subscription

      def initialize(subscription)
        @subscription = subscription
      end

      def plan_name
        subscription.plan_name
      end

      def status
        subscription.status
      end

      def renews_on
        subscription.renews_on
      end

      def cancellable?
        subscription.active? && !subscription.cancelled?
      end

      def uuid
        subscription.uuid
      end
    end
  end
end
```

The public reader is intentional. Templates should still prefer named view-model or
presenter methods over reaching through to `subscription`.


## Base Presenter

```ruby
# app/lib/presenters/base_presenter.rb
module Presenters
  class BasePresenter
    def initialize(object, view_context)
      @object = object
      @view_context = view_context
    end

    delegate :content_tag,
             :image_tag,
             :l,
             :link_to,
             :safe_join,
             :tag,
             to: :view_context


    private

    attr_reader :object, :view_context
  end
end
```


## Present Helper

```ruby
# app/helpers/application_helper.rb
module ApplicationHelper
  def present(name, with:)
    presenter_class = constantize_presenter_class(name, with)
    view_model = view_model_for_presenter(name)

    presenter_class.new(view_model, self)
  end


  private

  def constantize_presenter_class(name, with)
    with.to_s.constantize
  rescue NameError => error
    raise ArgumentError,
          "Cannot present #{name.inspect}: presenter class #{with.inspect} was not found. " \
          "Pass the full presenter class name, e.g. " \
          '"Presenters::Billing::SubscriptionSummaryPresenter". ' \
          "Original error: #{error.message}"
  end

  def view_model_for_presenter(name)
    return public_send(name) if respond_to?(name)

    raise ArgumentError,
          "Cannot present #{name.inspect}: no view-exposed method named #{name}. " \
          "Define helper_method :#{name} on the controller, or expose a helper method " \
          "that returns the view model."
  end
end
```

`name` is a view-exposed method returning the view model. `with` is an explicit
presenter class name. The helper raises clear `ArgumentError`s for missing presenter
classes or missing view-model methods, while preserving real exceptions raised inside
the view model or presenter.


## Presenter

```ruby
# app/lib/presenters/billing/subscription_summary_presenter.rb
module Presenters
  module Billing
    class SubscriptionSummaryPresenter < Presenters::BasePresenter
      def plan_name
        summary.plan_name
      end

      def status_badge
        content_tag(
          :span,
          I18n.t("billing.subscriptions.statuses.#{summary.status}"),
          class: "subscription-card__status subscription-card__status--#{summary.status}",
        )
      end

      def renewal_text
        return I18n.t("billing.subscriptions.no_renewal") unless summary.renews_on

        I18n.t(
          "billing.subscriptions.renews_on",
          date: l(summary.renews_on, format: :long),
        )
      end

      def show_cancellation_action?
        summary.cancellable?
      end

      def cancellation_action
        link_to(
          I18n.t("billing.subscriptions.cancel"),
          view_context.billing_subscription_cancellation_path(summary.uuid),
          class: "subscription-card__action",
        )
      end


      private

      def summary
        object
      end
    end
  end
end
```


## Slim Template

```slim
/ app/views/billing/subscriptions/show.html.slim
- subscription = present :subscription_summary, with: "Presenters::Billing::SubscriptionSummaryPresenter"

article.subscription-card
  header.subscription-card__header
    h1.subscription-card__heading = subscription.plan_name
    = subscription.status_badge

  p.subscription-card__renewal = subscription.renewal_text

  - if subscription.show_cancellation_action?
    footer.subscription-card__actions
      = subscription.cancellation_action
```


## Locale

```yaml
# config/locales/en.yml
en:
  billing:
    subscriptions:
      cancel: "Cancel subscription"
      no_renewal: "This subscription does not renew."
      renews_on: "Renews on %{date}"
      statuses:
        active: "Active"
        cancelled: "Cancelled"
        trial: "Trial"
```


## Responsibility Check

- Controller action stays clean.
- Controller private methods build and memoize the view model.
- View model exposes subscription-language data.
- Presenter builds view-language output.
- Template arranges semantic markup.
- Copy lives in I18n.
