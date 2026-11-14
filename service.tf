# The Cloud Run service.
#
# Cost: max_instances caps the whole service (summing every revision that gets traffic), min_instances = 0
# lets it scale to zero, and CPU is billed only while a request is handled. When the service is full, extra
# requests get HTTP 429 without reaching the container.
#
# Two things are left to the deploy pipeline on purpose, so a later terraform apply never undoes a deploy:
# - the image, which the pipeline sets by digest;
# - the traffic split, which a rollback changes.

resource "google_cloud_run_v2_service" "this" {
  project             = var.project_id
  name                = var.name
  location            = var.region
  description         = var.description
  ingress             = var.ingress
  deletion_protection = var.deletion_protection
  labels              = var.labels

  scaling {
    max_instance_count = var.max_instances
  }

  template {
    service_account                  = google_service_account.runtime.email
    timeout                          = "${var.timeout_seconds}s"
    max_instance_request_concurrency = var.concurrency

    scaling {
      min_instance_count = var.min_instances
      max_instance_count = var.max_instances
    }

    containers {
      image = var.image

      ports {
        container_port = var.container_port
      }

      resources {
        limits = {
          cpu    = var.cpu
          memory = var.memory
        }
        cpu_idle          = true
        startup_cpu_boost = true
      }

      dynamic "env" {
        for_each = var.env

        content {
          name  = env.key
          value = env.value
        }
      }

      # Read from Secret Manager when an instance starts. A secret without a value stops the revision from
      # starting, which is what you want: no silent fallback to an empty secret.
      dynamic "env" {
        for_each = google_secret_manager_secret.this

        content {
          name = env.key

          value_source {
            secret_key_ref {
              secret  = env.value.secret_id
              version = "latest"
            }
          }
        }
      }
    }
  }

  lifecycle {
    ignore_changes = [
      template[0].containers[0].image,
      traffic,
      client,
      client_version,
    ]
  }

  # The identity needs its roles and its secrets before the first revision starts.
  depends_on = [
    google_project_iam_member.runtime,
    google_secret_manager_secret_iam_member.runtime,
  ]
}

# Public access only when asked for. Without it, callers need roles/run.invoker.
resource "google_cloud_run_v2_service_iam_member" "public" {
  count = var.allow_unauthenticated ? 1 : 0

  project  = var.project_id
  location = google_cloud_run_v2_service.this.location
  name     = google_cloud_run_v2_service.this.name
  role     = "roles/run.invoker"
  member   = "allUsers"
}
