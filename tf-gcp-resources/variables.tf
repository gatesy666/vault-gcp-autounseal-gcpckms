

terraform {
  required_version = ">= 0.12"
}

variable "region" {
  type        = string
  default     = "europe-west2"
  description = "Region in which to create the cluster and run Vault."
}

variable "project" {
  type        = string
  default     = ""
  description = "Project ID where Terraform is authenticated to run to create additional projects. If provided, Terraform will create the GKE and Vault cluster inside this project. If not given, Terraform will generate a new project."
}

variable "project_id" {
  type        = string
  default     = ""
  description = "Project ID where Terraform is authenticated to run to create additional projects. If provided, Terraform will create the GKE and Vault cluster inside this project. If not given, Terraform will generate a new project."
}

# IAM Service Account

variable "service_account_iam_roles" {
  type = list(string)
  default = [
    "roles/logging.logWriter",
    "roles/monitoring.metricWriter",
    "roles/monitoring.viewer",
    "roles/cloudkms.cryptoKeyEncrypterDecrypter",
  ]
  description = "List of IAM roles to assign to the service account."
}

# variable "service_account_iam_roles" {
#   type = list(string)
#   default = []
#   description = "List of IAM roles to assign to the service account."
# }

variable "service_account_custom_iam_roles" {
  type        = list(string)
  default     = []
  description = "List of arbitrary additional IAM roles to attach to the service account on the Vault nodes."
}



variable "project_services" {
  type = list(string)
  default = [
    "cloudkms.googleapis.com",
    "cloudresourcemanager.googleapis.com",
    "container.googleapis.com",
    "compute.googleapis.com",
    "iam.googleapis.com",
    "logging.googleapis.com",
    "monitoring.googleapis.com",
  ]
  description = "List of services to enable on the project."
}