variable "shared_credentials_file" {
  default = "~/.aws/credentials"
}

variable "region" {
  default = "us-east-1"
}

variable "ssh_key_name" {
  default = "mission-control"
}

variable "cnc_hosts_count" {
  default = 0
}

variable "railsgoat_hosts_count" {
  default = 1
}
