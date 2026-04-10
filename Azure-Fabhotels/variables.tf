variable "location" {
  description = "Location of the application"
  type        = string
}

variable "region" {
  description = "Region of the application"
  type        = string
}

variable "environment" {
  description = "Environment of the application"
  type        = string
}

variable "address_space" {
  description = "Address space of the virtual network"
  type        = list(string)
}

variable "project" {
  description = "project name"
  type        = string
}

variable "private_subnet_address_prefixes" {
  description = "Address prefixes for the private subnet"
  type        = list(string)

}
variable "public_subnet_address_prefixes" {
  description = "Address prefixes for the public subnet"
  type        = list(string)
}

