# Mocked Google provider: no cloud account and no credentials needed.

mock_provider "google" {
  mock_data "google_project" {
    defaults = {
      number = "111111111111"
    }
  }
}

variables {
  billing_account       = "ABCDEF-012345-6789AB"
  project_id            = "example-project"
  amount                = 50
  notification_channels = ["projects/example-project/notificationChannels/123"]
}

run "watches_only_this_project" {
  assert {
    condition     = length(google_billing_budget.this.budget_filter[0].projects) == 1 && contains(google_billing_budget.this.budget_filter[0].projects, "projects/111111111111")
    error_message = "The budget must watch only this project, by number."
  }
}

run "alerts_on_spend_and_forecast" {
  assert {
    condition     = length([for r in google_billing_budget.this.threshold_rules : r if r.spend_basis == "CURRENT_SPEND"]) == 3
    error_message = "Three alerts on actual spend (50%, 90%, 100%) by default."
  }

  assert {
    condition     = length([for r in google_billing_budget.this.threshold_rules : r if r.spend_basis == "FORECASTED_SPEND"]) == 1
    error_message = "One early alert on the month's forecast by default."
  }

  assert {
    condition     = google_billing_budget.this.amount[0].specified_amount[0].units == "50"
    error_message = "The amount must be passed in whole units."
  }
}

run "rejects_silencing_the_budget" {
  command = plan

  variables {
    notification_channels          = []
    disable_default_iam_recipients = true
  }

  expect_failures = [var.disable_default_iam_recipients]
}

run "rejects_malformed_billing_account" {
  command = plan

  variables {
    billing_account = "my-billing-account"
  }

  expect_failures = [var.billing_account]
}
