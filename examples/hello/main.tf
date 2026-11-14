# A public "hello" API with every guard on: capped scale, its own identity, keyless deploys from one
# workflow on main, immutable images, alerts and a monthly budget.

resource "google_project_service" "apis" {
  for_each = toset([
    "artifactregistry.googleapis.com",
    "billingbudgets.googleapis.com",
    "cloudresourcemanager.googleapis.com",
    "iam.googleapis.com",
    "iamcredentials.googleapis.com",
    "monitoring.googleapis.com",
    "run.googleapis.com",
    "secretmanager.googleapis.com",
    "sts.googleapis.com",
  ])

  service            = each.value
  disable_on_destroy = false
}

resource "google_monitoring_notification_channel" "email" {
  display_name = "Alerts by email"
  type         = "email"

  labels = {
    email_address = var.alert_email
  }

  depends_on = [google_project_service.apis]
}

module "service" {
  source = "../.."

  project_id  = var.project_id
  region      = var.region
  name        = "hello"
  description = "Example service of terraform-google-secure-cloud-run."

  # Public on purpose: it is a demo API. The caps below are what keep the bill bounded.
  allow_unauthenticated = true
  max_instances         = 2
  concurrency           = 20

  env = {
    GREETING = "Hello"
  }

  # Secrets: add { ENV_VAR = "secret-id" } here and follow "Adding a secret" in the README.
  secrets = {}

  # This example calls no other Google API, so its identity needs no role at all.
  runtime_roles = []

  notification_channels = [google_monitoring_notification_channel.email.id]

  # Lets terraform destroy remove the example. Keep it true for anything real.
  deletion_protection = false

  labels = {
    app = "hello"
  }

  depends_on = [google_project_service.apis]
}

module "github_deploy" {
  source = "../../modules/github-oidc"

  project_id           = var.project_id
  github_repository    = var.github_repository
  github_repository_id = var.github_repository_id
  github_owner_id      = var.github_owner_id

  cloud_run_service = {
    name     = module.service.service_name
    location = var.region
  }

  runtime_service_account_name = module.service.runtime_service_account_name

  artifact_repository = {
    repository_id = module.service.artifact_repository_id
    location      = var.region
  }
}

module "budget" {
  source = "../../modules/budget"

  billing_account       = var.billing_account
  project_id            = var.project_id
  display_name          = "hello example"
  amount                = var.monthly_budget
  notification_channels = [google_monitoring_notification_channel.email.id]

  depends_on = [google_project_service.apis]
}
