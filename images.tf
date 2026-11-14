# Image repository next to the service (no cross-region traffic). Tags are immutable: once pushed, a tag can
# never point to a different image, and the deploy uses the digest anyway. The cleanup policy keeps the
# newest images for rollbacks and deletes the rest after a while, so storage does not grow forever.
# KEEP rules win over DELETE rules.

resource "google_artifact_registry_repository" "images" {
  count = var.create_artifact_repository ? 1 : 0

  project       = var.project_id
  location      = var.region
  repository_id = var.name
  description   = "Container images of the ${var.name} Cloud Run service."
  format        = "DOCKER"
  labels        = var.labels

  docker_config {
    immutable_tags = true
  }

  cleanup_policy_dry_run = false

  cleanup_policies {
    id     = "keep-most-recent"
    action = "KEEP"

    most_recent_versions {
      keep_count = var.image_keep_count
    }
  }

  cleanup_policies {
    id     = "delete-old"
    action = "DELETE"

    condition {
      tag_state  = "ANY"
      older_than = "${var.image_retention_days}d"
    }
  }
}
