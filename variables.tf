# --- Where -----------------------------------------------------------------------------------------------

variable "project_id" {
  description = "Google Cloud project that receives the service."
  type        = string
}

variable "region" {
  description = "Region of the service, its secrets and its image repository (for example, southamerica-east1)."
  type        = string
}

# --- What ------------------------------------------------------------------------------------------------

variable "name" {
  description = "Service name. Also names the image repository and the runtime service account."
  type        = string

  validation {
    condition     = can(regex("^[a-z][-a-z0-9]{0,47}[a-z0-9]$", var.name))
    error_message = "Use 2 to 49 lowercase letters, digits or hyphens, starting with a letter and not ending with a hyphen."
  }
}

variable "description" {
  description = "Free text shown in the Cloud Run console."
  type        = string
  default     = null
}

variable "image" {
  description = "Image used to create the service. Your deploy pipeline replaces it later, by digest, and Terraform ignores that change."
  type        = string
  default     = "us-docker.pkg.dev/cloudrun/container/hello"
}

variable "container_port" {
  description = "Port the container listens on."
  type        = number
  default     = 8080
}

# --- Cost ------------------------------------------------------------------------------------------------

variable "max_instances" {
  description = "Hard ceiling of instances for the whole service. No default on purpose: this number is your worst-case bill under a traffic spike or an attack. Requests above capacity get HTTP 429 and are not billed."
  type        = number

  validation {
    condition     = var.max_instances >= 1 && var.max_instances <= 100 && floor(var.max_instances) == var.max_instances
    error_message = "max_instances must be a whole number from 1 to 100."
  }
}

variable "min_instances" {
  description = "Instances kept warm. 0 means an idle service costs nothing."
  type        = number
  default     = 0

  validation {
    condition     = var.min_instances >= 0 && var.min_instances <= var.max_instances && floor(var.min_instances) == var.min_instances
    error_message = "min_instances must be a whole number from 0 to max_instances."
  }
}

variable "concurrency" {
  description = "Requests at the same time per instance. Together with max_instances, it caps how much work the service accepts."
  type        = number
  default     = 10

  validation {
    condition     = var.concurrency >= 1 && var.concurrency <= 1000
    error_message = "concurrency must be from 1 to 1000."
  }
}

variable "timeout_seconds" {
  description = "Maximum time for one request."
  type        = number
  default     = 60

  validation {
    condition     = var.timeout_seconds >= 1 && var.timeout_seconds <= 3600
    error_message = "timeout_seconds must be from 1 to 3600."
  }
}

variable "cpu" {
  description = "CPU limit per instance. CPU is only allocated while a request is being handled."
  type        = string
  default     = "1"
}

variable "memory" {
  description = "Memory limit per instance."
  type        = string
  default     = "512Mi"
}

# --- Access ----------------------------------------------------------------------------------------------

variable "allow_unauthenticated" {
  description = "Let anyone on the internet call the service. Off by default: a request denied by IAM never reaches the container and is not billed."
  type        = bool
  default     = false
}

variable "ingress" {
  description = "Where requests may come from."
  type        = string
  default     = "INGRESS_TRAFFIC_ALL"

  validation {
    condition = contains([
      "INGRESS_TRAFFIC_ALL",
      "INGRESS_TRAFFIC_INTERNAL_ONLY",
      "INGRESS_TRAFFIC_INTERNAL_LOAD_BALANCER",
    ], var.ingress)
    error_message = "Use INGRESS_TRAFFIC_ALL, INGRESS_TRAFFIC_INTERNAL_ONLY or INGRESS_TRAFFIC_INTERNAL_LOAD_BALANCER."
  }
}

variable "runtime_roles" {
  description = "Project roles for the service identity. Empty by default: add only what the code calls (for example, roles/datastore.user)."
  type        = set(string)
  default     = []

  validation {
    condition     = length(setintersection(var.runtime_roles, ["roles/owner", "roles/editor", "roles/viewer"])) == 0
    error_message = "Basic roles (owner, editor, viewer) are rejected. Grant the specific role the service needs."
  }
}

# --- Configuration and secrets ---------------------------------------------------------------------------

variable "env" {
  description = "Plain environment variables. Never put a secret here: these values are visible in the console and in the Terraform state."
  type        = map(string)
  default     = {}
}

variable "secrets" {
  description = "Secrets as environment variables: { ENV_VAR_NAME = \"secret-id\" }. The module creates each secret empty and lets only this service read it. The value is added outside Terraform (see README), so it never lands in code or state."
  type        = map(string)
  default     = {}

  validation {
    condition     = alltrue([for env_name, secret_id in var.secrets : can(regex("^[A-Z_][A-Z0-9_]*$", env_name)) && can(regex("^[A-Za-z0-9_-]{1,255}$", secret_id))])
    error_message = "Keys must be environment variable names (A-Z, 0-9, _) and values must be secret ids (letters, digits, - and _)."
  }

  validation {
    condition     = length(setintersection(keys(var.secrets), keys(var.env))) == 0
    error_message = "The same name cannot be both a plain variable (env) and a secret."
  }
}

# --- Images ----------------------------------------------------------------------------------------------

variable "create_artifact_repository" {
  description = "Create a Docker repository in Artifact Registry for this service."
  type        = bool
  default     = true
}

variable "image_keep_count" {
  description = "Most recent images always kept, so a rollback has somewhere to go."
  type        = number
  default     = 5
}

variable "image_retention_days" {
  description = "Older images beyond image_keep_count are deleted after this many days."
  type        = number
  default     = 30
}

# --- Safety and monitoring -------------------------------------------------------------------------------

variable "deletion_protection" {
  description = "Block terraform destroy and console deletion of the service until this is turned off."
  type        = bool
  default     = true
}

variable "notification_channels" {
  description = "Cloud Monitoring notification channels (ids). When empty, no alert policy is created."
  type        = list(string)
  default     = []
}

variable "alert_requests_per_5min" {
  description = "Requests in 5 minutes that count as a spike. Set it a few times above your normal peak."
  type        = number
  default     = 300

  validation {
    condition     = var.alert_requests_per_5min > 0
    error_message = "alert_requests_per_5min must be greater than 0."
  }
}

variable "alert_5xx_per_5min" {
  description = "Server errors (HTTP 5xx) in 5 minutes that trigger an alert."
  type        = number
  default     = 5

  validation {
    condition     = var.alert_5xx_per_5min > 0
    error_message = "alert_5xx_per_5min must be greater than 0."
  }
}

variable "labels" {
  description = "Labels added to every resource that supports them."
  type        = map(string)
  default     = {}
}
