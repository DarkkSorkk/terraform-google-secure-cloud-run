# Keyless deploys from GitHub Actions (Workload Identity Federation). No service account key is created or
# stored anywhere: GitHub signs a short-lived token for each run, and Google exchanges it for access.
#
# Three locks, from the outside in:
# 1. The provider accepts tokens only from one repository, matched by numeric id and owner id.
# 2. The deploy identity can be used only by one workflow file running on one branch. A pull request, a fork
#    or another workflow in the same repository gets nothing.
# 3. The deploy identity can only push images to one repository and update one service. roles/run.developer
#    cannot change IAM, so a deploy can never make the service public.

locals {
  workflow_ref = "${var.github_repository}/${var.deploy_workflow}@refs/heads/${var.deploy_branch}"
}

resource "google_iam_workload_identity_pool" "github" {
  project                   = var.project_id
  workload_identity_pool_id = var.pool_id
  display_name              = "GitHub Actions"
  description               = "Keyless authentication for GitHub Actions."
}

resource "google_iam_workload_identity_pool_provider" "github" {
  project                            = var.project_id
  workload_identity_pool_id          = google_iam_workload_identity_pool.github.workload_identity_pool_id
  workload_identity_pool_provider_id = var.provider_id
  display_name                       = "GitHub Actions"
  description                        = "Accepts only ${var.github_repository} (repository ${var.github_repository_id}, owner ${var.github_owner_id})."

  attribute_mapping = {
    "google.subject"                = "assertion.sub"
    "attribute.repository"          = "assertion.repository"
    "attribute.repository_id"       = "assertion.repository_id"
    "attribute.repository_owner_id" = "assertion.repository_owner_id"
    "attribute.ref"                 = "assertion.ref"
    "attribute.workflow_ref"        = "assertion.workflow_ref"
  }

  attribute_condition = "assertion.repository_id == '${var.github_repository_id}' && assertion.repository_owner_id == '${var.github_owner_id}'"

  oidc {
    issuer_uri = "https://token.actions.githubusercontent.com"
  }
}

resource "google_service_account" "deploy" {
  project      = var.project_id
  account_id   = var.service_account_id
  display_name = "GitHub Actions deploy: ${var.cloud_run_service.name}"
  description  = "Pushes images and deploys ${var.cloud_run_service.name}. Usable only by ${var.deploy_workflow} on ${var.deploy_branch}."
}

resource "google_service_account_iam_member" "federation" {
  service_account_id = google_service_account.deploy.name
  role               = "roles/iam.workloadIdentityUser"
  member             = "principalSet://iam.googleapis.com/${google_iam_workload_identity_pool.github.name}/attribute.workflow_ref/${local.workflow_ref}"
}

# Update this service, and only this one.
resource "google_cloud_run_v2_service_iam_member" "deploy" {
  project  = var.project_id
  location = var.cloud_run_service.location
  name     = var.cloud_run_service.name
  role     = "roles/run.developer"
  member   = google_service_account.deploy.member
}

# A new revision runs as the service's identity, so the deploy must be allowed to act as it (and only it).
resource "google_service_account_iam_member" "act_as_runtime" {
  service_account_id = var.runtime_service_account_name
  role               = "roles/iam.serviceAccountUser"
  member             = google_service_account.deploy.member
}

# Push images to this repository, and only this one.
resource "google_artifact_registry_repository_iam_member" "deploy" {
  count = var.artifact_repository == null ? 0 : 1

  project    = var.project_id
  location   = var.artifact_repository.location
  repository = var.artifact_repository.repository_id
  role       = "roles/artifactregistry.writer"
  member     = google_service_account.deploy.member
}
