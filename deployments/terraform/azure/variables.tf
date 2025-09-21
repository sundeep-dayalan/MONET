variable "project_name" {
  type        = string
  description = "The name of the project."
  default     = "sage"
}

variable "location" {
  type        = string
  description = "The Azure region to deploy to."
  default     = "Central US"
}

variable "environment" {
  type        = string
  description = "The deployment environment."
  default     = "prod"
}
