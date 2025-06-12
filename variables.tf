# Variables for reuse
variable "location" {
  default = "australiaeast"
  description = "The Azure region where resources will be created."
}

variable "subscription_id" {
  description = "The Azure subscription ID where resources will be created."
}
variable "client_id" {
  description = "The Azure client ID for authentication."
}
variable "client_secret" {
  description = "The Azure client secret for authentication."
}
variable "tenant_id" {
  description = "The Azure tenant ID for authentication."
}