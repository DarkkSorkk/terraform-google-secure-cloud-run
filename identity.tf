# The service runs as its own identity, never as the project's default compute account (which usually holds
# the broad Editor role). It starts with no roles at all; runtime_roles adds only what the code calls.
# Every binding in this module is additive ("member"): it never removes bindings that already exist.

locals {
  # Service account ids have 6 to 30 characters.
  runtime_account_id = "${substr(var.name, 0, 25)}-run"
}

resource "google_service_account" "runtime" {
  project      = var.project_id
  account_id   = local.runtime_account_id
  display_name = "Cloud Run runtime: ${var.name}"
  description  = "Identity of the ${var.name} Cloud Run service. Holds only the roles this service needs."
}

resource "google_project_iam_member" "runtime" {
  for_each = var.runtime_roles

  project = var.project_id
  role    = each.value
  member  = google_service_account.runtime.member
}
