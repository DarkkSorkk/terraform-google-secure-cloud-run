terraform {
  # 1.9 or newer: variable validations below compare one variable with another.
  required_version = ">= 1.9"

  required_providers {
    google = {
      source = "hashicorp/google"
      # Tested with 8.10. The upper bound avoids a surprise major upgrade.
      version = ">= 8.0, < 9.0"
    }
  }
}
