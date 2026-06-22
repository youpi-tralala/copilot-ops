output "public_ip" {
  description = "Public IP address of the VM"
  value       = azurerm_public_ip.pip.ip_address
}

output "ssh_connection" {
  description = "Example SSH command"
  value       = "ssh -i ${var.ssh_public_key_path} ${var.admin_username}@${azurerm_public_ip.pip.ip_address}"
}
