variable "project_id" {
  description = "Project for the example. Prefer a new, empty project."
  type        = string
}

variable "region" {
  description = "Region of the service."
  type        = string
  default     = "southamerica-east1"
}

variable "billing_account" {
  description = "Billing account of the project (XXXXXX-XXXXXX-XXXXXX), for the budget."
  type        = string
}

variable "monthly_budget" {
  description = "Monthly budget, in the billing account's currency."
  type        = number
  default     = 50
}

variable "alert_email" {
  description = "Email that receives the alerts and the budget notices."
  type        = string
}

variable "github_repository" {
  description = "Your repository that will deploy the service (owner/name)."
  type        = string
}

variable "github_repository_id" {
  description = "Numeric id of that repository: gh api repos/OWNER/NAME --jq .id"
  type        = string
}

variable "github_owner_id" {
  description = "Numeric id of the owner: gh api users/OWNER --jq .id"
  type        = string
}
