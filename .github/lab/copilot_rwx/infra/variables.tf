variable "resource_group_name" {
  description = "Name of the resource group"
  type        = string
}

variable "location" {
  description = "Azure region (eg: westeurope, francecentral)"
  type        = string
}

variable "vm_name" {
  description = "VM name"
  type        = string
}

variable "vm_size" {
  description = "VM SKU (e.g. Standard_D8s_v3)"
  type        = string
}

variable "admin_username" {
  description = "Admin username for the VM"
  type        = string
}

variable "ssh_public_key_path" {
  description = "Path to SSH public key on the machine running terraform"
  type        = string
}

variable "git_repo" {
  description = "Public git repository URL to clone during bootstrap"
  type        = string
}

variable "git_branch" {
  description = "Branch to checkout from git_repo"
  type        = string
  default     = "main"
}
