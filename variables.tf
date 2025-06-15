# Variables for reuse
variable "location" {
  type        = string
  default     = "australiaeast"
  description = "The Azure region where resources will be created."

}

variable "subscription_id" {
  type        = string
  description = "The Azure subscription ID where resources will be created."
}
variable "client_id" {
  type        = string
  description = "The Azure client ID for authentication."
}
variable "client_secret" {
  type        = string
  sensitive   = true
  description = "The Azure client secret for authentication."
}
variable "tenant_id" {
  type        = string
  description = "The Azure tenant ID for authentication."
}
