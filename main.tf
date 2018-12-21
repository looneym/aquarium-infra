provider "aws" {
  region                  = "${var.region}"
  shared_credentials_file = "${var.shared_credentials_file}"
}

data "aws_ami" "docker" {
  filter {
    name   = "state"
    values = ["available"]
  }

  filter {
    name   = "tag:Name"
    values = ["docker"]
  }

  most_recent = true
}

module "network" {
  source = "./common/network"
}

module "cnc_hosts" {
  source                 = "./modules/ec2"
  ami                    = "${data.aws_ami.docker.id}"
  count                  = "${var.cnc_hosts_count}"
  subnet_id              = "${module.network.subnet_id}"
  vpc_security_group_ids = ["${module.network.sg_ssh_id}", "${module.network.sg_web_id}"]
  key_name               = "${var.ssh_key_name}"
  instance_type          = "t2.small"
}

module "railsgoat_hosts" {
  source                 = "./modules/ec2"
  ami                    = "${data.aws_ami.docker.id}"
  count                  = "${var.railsgoat_hosts_count}"
  subnet_id              = "${module.network.subnet_id}"
  vpc_security_group_ids = ["${module.network.sg_ssh_id}", "${module.network.sg_web_id}"]
  key_name               = "${var.ssh_key_name}"
  instance_type          = "t2.small"
}

data "template_file" "ansible_inventory_template" {
  template = "${file("${path.module}/templates/ansible_inventory")}"
  depends_on = [
    "module.cnc_hosts",
    "module.railsgoat_hosts",
  ]
  vars {
   cnc_hosts = "${join("\n", module.cnc_hosts.instance_public_ips)}"
   railsgoat_hosts = "${join("\n", module.railsgoat_hosts.instance_public_ips)}"
  }
}

resource "null_resource" "ansible_inventory" {
  triggers {
    template_rendered = "${data.template_file.ansible_inventory_template.rendered}"
  }
  provisioner "local-exec" {
    command = "echo '${data.template_file.ansible_inventory_template.rendered}' > ansible_inventory.cfg"
  }
}

resource "aws_db_instance" "railsgoat_db" {  
  allocated_storage        = 5  # gigabytes
  backup_retention_period  = 7  # in days
  db_subnet_group_name     = "${module.network.db_subnet_group_id}"
  engine                   = "postgres"
  engine_version           = "9.5.4"
  identifier               = "railsgoat-db"
  instance_class           = "db.t2.micro"
  multi_az                 = false
  name                     = "railsgoat_db"
  port                     = 5432
  publicly_accessible      = false
  storage_encrypted        = false 
  storage_type             = "gp2"
  password                 = "railsgoat"
  username                 = "railsgoat"
  skip_final_snapshot      = true
  vpc_security_group_ids   = ["${module.network.db_security_group_id}"]
}

data "template_file" "db_credentials_template" {
  template = "${file("${path.module}/templates/db_credentials")}"
  depends_on = [
    "aws_db_instance.railsgoat_db",
  ]
  vars {
   username = "${aws_db_instance.railsgoat_db.username}"
   password = "${aws_db_instance.railsgoat_db.password}"
   address = "${aws_db_instance.railsgoat_db.address}"
  }
}

resource "null_resource" "db_credentials" {
  triggers {
    template_rendered = "${data.template_file.db_credentials_template.rendered}"
  }
  provisioner "local-exec" {
    command = "echo '${data.template_file.db_credentials_template.rendered}' > db_credentials.cfg"
  }
}
