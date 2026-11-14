output "service_uri" {
  description = "URL of the example API."
  value       = module.service.service_uri
}

output "github_actions_variables" {
  description = "Repository variables for the deploy workflow (Settings > Secrets and variables > Actions > Variables). None of them is a secret."
  value = {
    GCP_WIF_PROVIDER = module.github_deploy.workload_identity_provider
    GCP_DEPLOY_SA    = module.github_deploy.deploy_service_account_email
    GCP_PROJECT      = var.project_id
    GCP_REGION       = var.region
    SERVICE          = module.service.service_name
    IMAGE            = module.service.image_path
  }
}
