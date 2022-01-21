output "ssh-cmd" {
  value = "ssh -i ../ec2.pem ec2-user@${aws_instance.docker-host.public_dns}"
}

output "domain-name" {
  value = "https://${var.domain_name}"
}

output "traefik-url" {
  value = "https://traefik.${var.domain_name}"
}

output "portainer-url" {
  value = "https://portainer.${var.domain_name}"
}

output "nginx-url" {
  value = "https://nginx.${var.domain_name}"
}

output "admin-password" {
  value = replace(bcrypt(var.admin_password, 6), "$", "$$")
#  value = var.admin_password
  #sensitive = true
}
