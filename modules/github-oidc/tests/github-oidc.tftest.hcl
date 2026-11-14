# Mocked Google provider: no cloud account and no credentials needed.

mock_provider "google" {
  # Realistic values for computed attributes that other resources validate (IAM member format).
  mock_resource "google_service_account" {
    defaults = {
      email  = "github-deploy@example-project.iam.gserviceaccount.com"
      member = "serviceAccount:github-deploy@example-project.iam.gserviceaccount.com"
      name   = "projects/example-project/serviceAccounts/github-deploy@example-project.iam.gserviceaccount.com"
    }
  }

  mock_resource "google_iam_workload_identity_pool" {
    defaults = {
      name = "projects/111111111111/locations/global/workloadIdentityPools/github-actions"
    }
  }

  mock_resource "google_iam_workload_identity_pool_provider" {
    defaults = {
      name = "projects/111111111111/locations/global/workloadIdentityPools/github-actions/providers/github"
    }
  }
}

variables {
  project_id           = "example-project"
  github_repository    = "octo-org/hello"
  github_repository_id = "123456789"
  github_owner_id      = "987654321"

  cloud_run_service = {
    name     = "hello"
    location = "southamerica-east1"
  }

  runtime_service_account_name = "projects/example-project/serviceAccounts/hello-run@example-project.iam.gserviceaccount.com"

  artifact_repository = {
    repository_id = "hello"
    location      = "southamerica-east1"
  }
}

run "accepts_only_one_repository_by_id" {
  assert {
    condition     = google_iam_workload_identity_pool_provider.github.attribute_condition == "assertion.repository_id == '123456789' && assertion.repository_owner_id == '987654321'"
    error_message = "The provider must accept tokens only from the repository and owner ids."
  }

  assert {
    condition     = google_iam_workload_identity_pool_provider.github.oidc[0].issuer_uri == "https://token.actions.githubusercontent.com"
    error_message = "The provider must trust only GitHub's token issuer."
  }
}

run "deploys_only_from_one_workflow_on_main" {
  assert {
    condition     = endswith(google_service_account_iam_member.federation.member, "/attribute.workflow_ref/octo-org/hello/.github/workflows/deploy.yml@refs/heads/main")
    error_message = "Only deploy.yml running on main may use the deploy identity."
  }

  assert {
    condition     = google_service_account_iam_member.federation.role == "roles/iam.workloadIdentityUser"
    error_message = "Federation must use workloadIdentityUser."
  }
}

run "deploy_touches_only_this_service_and_repository" {
  assert {
    condition     = google_cloud_run_v2_service_iam_member.deploy.name == "hello" && google_cloud_run_v2_service_iam_member.deploy.role == "roles/run.developer"
    error_message = "The deploy identity must be scoped to this service, with a role that cannot change IAM."
  }

  assert {
    condition     = google_artifact_registry_repository_iam_member.deploy[0].repository == "hello" && google_artifact_registry_repository_iam_member.deploy[0].role == "roles/artifactregistry.writer"
    error_message = "The deploy identity must push only to this repository."
  }

  assert {
    condition     = google_service_account_iam_member.act_as_runtime.service_account_id == var.runtime_service_account_name
    error_message = "The deploy identity may act only as this service's runtime identity."
  }
}

run "other_branch" {
  variables {
    deploy_branch = "release"
  }

  assert {
    condition     = endswith(google_service_account_iam_member.federation.member, "deploy.yml@refs/heads/release")
    error_message = "deploy_branch must change the allowed branch."
  }
}

run "rejects_repository_name_instead_of_id" {
  command = plan

  variables {
    github_repository_id = "octo-org/hello"
  }

  expect_failures = [var.github_repository_id]
}

run "rejects_workflow_outside_github_folder" {
  command = plan

  variables {
    deploy_workflow = "scripts/deploy.yml"
  }

  expect_failures = [var.deploy_workflow]
}
