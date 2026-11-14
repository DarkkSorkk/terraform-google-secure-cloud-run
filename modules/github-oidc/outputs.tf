output "workload_identity_provider" {
  description = "Full name of the provider, for google-github-actions/auth (workload_identity_provider)."
  value       = google_iam_workload_identity_pool_provider.github.name
}

output "deploy_service_account_email" {
  description = "Deploy identity, for google-github-actions/auth (service_account)."
  value       = google_service_account.deploy.email
}

output "allowed_workflow" {
  description = "The only workflow run that can deploy."
  value       = local.workflow_ref
}
