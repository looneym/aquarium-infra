output "sg_ssh_id" {
  value = "${aws_security_group.easy-ec2-allow_ssh.id}"
}

output "sg_web_id" {
  value = "${aws_security_group.easy-ec2-web_server.id}"
}

output "subnet_id" {
  value = "${aws_subnet.easy-ec2-subnet.id}"
}

output "db_security_group_id" {
  value = "${aws_security_group.db-security-group.id}"
}

output "db_subnet_group_id" {
  value = "${aws_db_subnet_group.db-subnet-group.id}"
}
