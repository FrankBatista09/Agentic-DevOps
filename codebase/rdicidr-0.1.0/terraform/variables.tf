variable "location" {
  type        = string
  description = "Azure region for deployment"
  default     = "eastus"
}

variable "app_name" {
  type        = string
  description = "Application name"
  default     = "rdicidr"

  validation {
    condition     = can(regex("^[a-z][a-z0-9]{2,12}$", var.app_name))
    error_message = "app_name must be 3-13 lowercase letters or digits and start with a letter."
  }
}

variable "environment" {
  type        = string
  description = "Deployment environment (devel or stage). Selects names, tags and the network range."

  validation {
    condition     = contains(["devel", "stage"], var.environment)
    error_message = "environment must be either devel or stage."
  }
}

variable "vnet_address_spaces" {
  type        = map(string)
  description = "Virtual network address space per environment (the networks must not overlap)"
  default = {
    devel = "10.10.0.0/16"
    stage = "10.20.0.0/16"
  }
}

variable "image_name" {
  type        = string
  description = "Repository name of the application image in the registry"
  default     = "rdicidr"
}

variable "image_tag" {
  type        = string
  description = "Image tag to deploy (the pipeline passes the git commit SHA)"
}

variable "container_port" {
  type        = number
  description = "Port the container listens on"
  default     = 80
}

variable "health_check_path" {
  type        = string
  description = "Health check endpoint path"
  default     = "/health"
}

variable "min_replicas" {
  type        = number
  description = "Minimum number of container replicas (at least 1, so the health check is always served)"
  default     = 1

  validation {
    condition     = var.min_replicas >= 1
    error_message = "min_replicas must be at least 1."
  }
}

variable "max_replicas" {
  type        = number
  description = "Maximum number of container replicas"
  default     = 2
}

variable "log_retention_days" {
  type        = number
  description = "Log Analytics retention in days"
  default     = 30
}
