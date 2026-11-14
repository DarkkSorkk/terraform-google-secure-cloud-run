variable "project_id" {
  description = "Project of the Cloud Run service."
  type        = string
}

variable "pool_id" {
  description = "Workload identity pool to create."
  type        = string
  default     = "github-actions"
}

variable "provider_id" {
  description = "OIDC provider to create inside the pool."
  type        = string
  default     = "github"
}

# --- Which repository -------------------------------------------------------------------------------------

variable "github_repository" {
  description = "Repository allowed to deploy, as owner/name."
  type        = string

  validation {
    condition     = can(regex("^[A-Za-z0-9-]+/[A-Za-z0-9._-]+$", var.github_repository))
    error_message = "Use the owner/name form, for example octo-org/hello."
  }
}

variable "github_repository_id" {
  description = "Numeric id of that repository (gh api repos/OWNER/NAME --jq .id). Unlike the name, it never changes and cannot be reused by someone who re-creates a deleted repository with the same name."
  type        = string

  validation {
    condition     = can(regex("^[0-9]+$", var.github_repository_id))
    error_message = "github_repository_id must be the numeric id, not the name."
  }
}

variable "github_owner_id" {
  description = "Numeric id of the repository owner (gh api users/OWNER --jq .id)."
  type        = string

  validation {
    condition     = can(regex("^[0-9]+$", var.github_owner_id))
    error_message = "github_owner_id must be the numeric id, not the login."
  }
}

variable "deploy_workflow" {
  description = "The only workflow file allowed to deploy."
  type        = string
  default     = ".github/workflows/deploy.yml"

  validation {
    condition     = can(regex("^\\.github/workflows/[A-Za-z0-9._-]+\\.ya?ml$", var.deploy_workflow))
    error_message = "Use a path like .github/workflows/deploy.yml."
  }
}

variable "deploy_branch" {
  description = "The only branch allowed to deploy."
  type        = string
  default     = "main"
}

# --- What the deploy may touch -----------------------------------------------------------------------------

variable "service_account_id" {
  description = "Id of the deploy service account to create."
  type        = string
  default     = "github-deploy"
}

variable "cloud_run_service" {
  description = "The service the deploy may update: { name, location }."
  type = object({
    name     = string
    location = string
  })
}

variable "runtime_service_account_name" {
  description = "Full resource name of the service's runtime identity (output runtime_service_account_name of the root module). Deploying a revision requires acting as it."
  type        = string
}

variable "artifact_repository" {
  description = "Image repository the deploy may push to: { repository_id, location }. Null to skip."
  type = object({
    repository_id = string
    location      = string
  })
  default = null
}
