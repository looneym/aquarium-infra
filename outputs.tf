output "ssh_key_name" {
  value = "${var.ssh_key_name}"
}

output "cnc_hosts_public_ips" {
  value = "${module.cnc_hosts.instance_public_ips}"
}

output "railsgoat_hosts_public_ips" {
  value = "${module.railsgoat_hosts.instance_public_ips}"
}
