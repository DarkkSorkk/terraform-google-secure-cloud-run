output "service_name" {
  description = "Name of the Cloud Run service."
  value       = google_cloud_run_v2_service.this.name
}

output "service_uri" {
  description = "URL of the service. Answers 403 while allow_unauthenticated is false."
  value       = google_cloud_run_v2_service.this.uri
}

output "runtime_service_account_email" {
  description = "Email of the identity the service runs as."
  value       = google_service_account.runtime.email
}

output "runtime_service_account_name" {
  description = "Full resource name of the runtime identity (projects/.../serviceAccounts/...), for IAM bindings on it."
  value       = google_service_account.runtime.name
}

output "artifact_repository_id" {
  description = "Id of the image repository, or null when create_artifact_repository is false."
  value       = var.create_artifact_repository ? google_artifact_registry_repository.images[0].repository_id : null
}

output "image_path" {
  description = "Where to push images (without tag), or null when create_artifact_repository is false."
  value       = var.create_artifact_repository ? "${var.region}-docker.pkg.dev/${var.project_id}/${google_artifact_registry_repository.images[0].repository_id}/${var.name}" : null
}

output "secret_ids" {
  description = "Secrets created by the module, by environment variable name. Add their values with gcloud."
  value       = { for env_name, secret in google_secret_manager_secret.this : env_name => secret.secret_id }
}
