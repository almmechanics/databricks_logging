variable "location" {
  description = "Common resource group to target"
  type        = string
  default     = "centralus"
}

variable "instance" {
  type    = number
  default = 0
}

variable "prefix" {
  type    = string
  default = "datainfra"
}

variable "suffix" {
  type    = string
  default = "logging"
}

variable "client_secret" {
  type    = string
  default = "Invalid"
}

variable "client_id" {
  type    = string
  default = "Invalid"

}

variable "subscription_id" {
  type    = string
  default = "Invalid"

}

variable "tenant_id" {
  type    = string
  default = "Invalid"
}

variable "ai_jar_version" {
  type    = string
  default = "2.6.1"
}