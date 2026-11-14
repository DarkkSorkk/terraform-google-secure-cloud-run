# Runs with a mocked Google provider: no cloud account, no credentials, nothing created. That is why CI can
# run these on every pull request without holding any secret.

mock_provider "google" {
  # Realistic values for computed attributes that other resources validate (IAM member format).
  mock_resource "google_service_account" {
    defaults = {
      email  = "hello-run@example-project.iam.gserviceaccount.com"
      member = "serviceAccount:hello-run@example-project.iam.gserviceaccount.com"
      name   = "projects/example-project/serviceAccounts/hello-run@example-project.iam.gserviceaccount.com"
    }
  }
}

variables {
  project_id    = "example-project"
  region        = "southamerica-east1"
  name          = "hello"
  max_instances = 2
}

run "private_and_capped_by_default" {
  assert {
    condition     = length(google_cloud_run_v2_service_iam_member.public) == 0
    error_message = "The service must not be public unless allow_unauthenticated is true."
  }

  assert {
    condition     = google_cloud_run_v2_service.this.scaling[0].max_instance_count == 2
    error_message = "The service-wide instance cap must be max_instances."
  }

  assert {
    condition     = google_cloud_run_v2_service.this.template[0].scaling[0].max_instance_count == 2 && google_cloud_run_v2_service.this.template[0].scaling[0].min_instance_count == 0
    error_message = "The revision must scale from 0 up to max_instances."
  }

  assert {
    condition     = google_cloud_run_v2_service.this.template[0].containers[0].resources[0].cpu_idle
    error_message = "CPU must be billed only while handling requests."
  }

  assert {
    condition     = google_cloud_run_v2_service.this.deletion_protection
    error_message = "Deletion protection must be on by default."
  }
}

run "runs_as_its_own_identity_with_no_roles" {
  assert {
    condition     = google_cloud_run_v2_service.this.template[0].service_account == google_service_account.runtime.email
    error_message = "The service must run as the identity created by the module."
  }

  assert {
    condition     = google_service_account.runtime.account_id == "hello-run"
    error_message = "The runtime identity must be named after the service."
  }

  assert {
    condition     = length(google_project_iam_member.runtime) == 0
    error_message = "The runtime identity must start with no project roles."
  }
}

run "public_only_when_asked" {
  variables {
    allow_unauthenticated = true
  }

  assert {
    condition     = length(google_cloud_run_v2_service_iam_member.public) == 1 && google_cloud_run_v2_service_iam_member.public[0].member == "allUsers" && google_cloud_run_v2_service_iam_member.public[0].role == "roles/run.invoker"
    error_message = "allow_unauthenticated must grant run.invoker to allUsers, and nothing more."
  }
}

run "secrets_reach_only_this_service" {
  variables {
    env     = { GREETING = "Hello" }
    secrets = { API_TOKEN = "hello-api-token" }
  }

  assert {
    condition     = google_secret_manager_secret.this["API_TOKEN"].secret_id == "hello-api-token"
    error_message = "The secret must be created with the given id."
  }

  assert {
    condition     = google_secret_manager_secret_iam_member.runtime["API_TOKEN"].member == google_service_account.runtime.member && google_secret_manager_secret_iam_member.runtime["API_TOKEN"].role == "roles/secretmanager.secretAccessor"
    error_message = "Only the runtime identity may read the secret."
  }

  assert {
    condition     = one([for e in google_cloud_run_v2_service.this.template[0].containers[0].env : e if e.name == "API_TOKEN"]).value_source[0].secret_key_ref[0].secret == "hello-api-token"
    error_message = "The secret must reach the container through Secret Manager, not as a plain value."
  }

  assert {
    condition     = one([for e in google_cloud_run_v2_service.this.template[0].containers[0].env : e if e.name == "GREETING"]).value == "Hello"
    error_message = "Plain variables must be passed as they are."
  }
}

run "images_are_immutable_and_cleaned_up" {
  assert {
    condition     = google_artifact_registry_repository.images[0].docker_config[0].immutable_tags
    error_message = "Image tags must be immutable."
  }

  assert {
    condition     = length(google_artifact_registry_repository.images[0].cleanup_policies) == 2
    error_message = "The repository must keep recent images and delete old ones."
  }
}

run "alerts_only_with_channels" {
  assert {
    condition     = length(google_monitoring_alert_policy.request_spike) == 0 && length(google_monitoring_alert_policy.server_errors) == 0
    error_message = "No alert policy without notification channels."
  }
}

run "alerts_when_channels_are_given" {
  variables {
    notification_channels = ["projects/example-project/notificationChannels/123"]
  }

  assert {
    condition     = length(google_monitoring_alert_policy.request_spike) == 1 && length(google_monitoring_alert_policy.server_errors) == 1
    error_message = "Both alert policies must exist when channels are given."
  }
}

# --- Mistakes caught before anything is created ------------------------------------------------------------

run "rejects_basic_roles" {
  command = plan

  variables {
    runtime_roles = ["roles/editor"]
  }

  expect_failures = [var.runtime_roles]
}

run "rejects_no_instance_cap" {
  command = plan

  variables {
    max_instances = 0
  }

  expect_failures = [var.max_instances]
}

run "rejects_more_warm_instances_than_the_cap" {
  command = plan

  variables {
    min_instances = 3
  }

  expect_failures = [var.min_instances]
}

run "rejects_a_name_used_as_both_plain_variable_and_secret" {
  command = plan

  variables {
    env     = { API_TOKEN = "oops" }
    secrets = { API_TOKEN = "hello-api-token" }
  }

  expect_failures = [var.secrets]
}

run "rejects_invalid_service_name" {
  command = plan

  variables {
    name = "Hello_World"
  }

  expect_failures = [var.name]
}
