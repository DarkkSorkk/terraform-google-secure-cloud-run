terraform {
  required_version = ">= 1.9"

  required_providers {
    google = {
      source  = "hashicorp/google"
      version = ">= 8.0, < 9.0"
    }
  }

  # For real use, keep the state in a private, versioned bucket:
  # backend "gcs" {
  #   bucket = "YOUR-PROJECT-tfstate"
  #   prefix = "hello"
  # }
}

provider "google" {
  project = var.project_id
  region  = var.region

  # Bill API quota (budgets, IAM) to this project. Without it, gcloud's default quota project, which may be
  # a different project, would be charged and could lack the APIs.
  billing_project       = var.project_id
  user_project_override = true

  default_labels = {
    managed-by = "terraform"
  }
}
