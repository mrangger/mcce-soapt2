variable "admin_password" {
  description = "This password is used for login in traefik and portainer app"
  type = string
  sensitive = true
}

variable "dns_username" {
  description = "Username for dynamic domain name assingnment"
  type = string
}

variable "dns_password" {
  description = "Password for dynamic domain name assingnment"
  type = string
  sensitive = true
}

variable "dns_token" {
  description = "Token to authenticate for dnschallenge in letsencrypt"
  type = string
  sensitive = true
}

variable "domain_name" {
  description = "Domain name for dynamic domain name assingnment"
  type = string
}

variable "email_address" {
  description = "E-Mail-Address for letsencrypt"
  type = string
}



