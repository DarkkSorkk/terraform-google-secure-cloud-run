variable "billing_account" {
  description = "Billing account id (XXXXXX-XXXXXX-XXXXXX)."
  type        = string

  validation {
    condition     = can(regex("^[A-F0-9]{6}-[A-F0-9]{6}-[A-F0-9]{6}$", var.billing_account))
    error_message = "Use the billing account id, in the XXXXXX-XXXXXX-XXXXXX form."
  }
}

variable "project_id" {
  description = "Project whose spending the budget watches."
  type        = string
}

variable "display_name" {
  description = "Name of the budget in the billing console."
  type        = string
  default     = "Monthly budget"
}

variable "amount" {
  description = "Monthly amount, in the billing account's currency, in whole units."
  type        = number

  validation {
    condition     = var.amount >= 1 && floor(var.amount) == var.amount
    error_message = "amount must be a whole number of at least 1."
  }
}

variable "currency_code" {
  description = "Currency of the amount (for example, BRL or USD). Must match the billing account. Null uses the account's currency."
  type        = string
  default     = null
}

variable "thresholds" {
  description = "Fractions of the amount, already spent, that send an alert."
  type        = list(number)
  default     = [0.5, 0.9, 1.0]

  validation {
    condition     = length(var.thresholds) > 0 && alltrue([for t in var.thresholds : t > 0])
    error_message = "Give at least one threshold, each greater than 0."
  }
}

variable "forecast_threshold" {
  description = "Fraction of the amount that, if the month's forecast reaches it, sends an early alert. Null to skip."
  type        = number
  default     = 1.0
}

variable "notification_channels" {
  description = "Cloud Monitoring notification channels (ids) that receive the alerts."
  type        = list(string)
  default     = []
}

variable "pubsub_topic" {
  description = "Pub/Sub topic (projects/PROJECT/topics/NAME) that receives every budget update, for automation. Null to skip."
  type        = string
  default     = null
}

variable "disable_default_iam_recipients" {
  description = "Stop the default emails to billing admins. Only allowed when another channel is set."
  type        = bool
  default     = false

  validation {
    condition     = !var.disable_default_iam_recipients || length(var.notification_channels) > 0 || var.pubsub_topic != null
    error_message = "Turning off the default emails without notification_channels or pubsub_topic would silence the budget."
  }
}
