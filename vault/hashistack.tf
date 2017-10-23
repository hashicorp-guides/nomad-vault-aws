terraform {
  required_version = ">= 0.9.3"
}

resource "random_id" "environment_name" {
  byte_length = 4
  prefix      = "${var.environment_name_prefix}-"
}

module "network-aws-simple" {
  source           = "git@github.com:hashicorp-modules/network-aws-simple.git"
  environment_name = "${random_id.environment_name.hex}"
  vpc_cidrs_public = ["172.19.0.0/20", "172.19.16.0/20"]
}

module "ssh-keypair-aws" {
  source       = "git@github.com:hashicorp-modules/ssh-keypair-aws.git"
  ssh_key_name = "${random_id.environment_name.hex}"
}

data "aws_ami" "hashistack" {
  most_recent = true
  owners      = ["362381645759"] # hc-se-demos Hashicorp Demos New Account

  filter {
    name   = "tag:System"
    values = ["HashiStack"]
  }

  filter {
    name   = "tag:Environment"
    values = ["${var.environment}"]
  }

  filter {
    name   = "tag:OS"
    values = ["${var.os}"]
  }

  filter {
    name   = "tag:OS-Version"
    values = ["${var.os_version}"]
  }

  filter {
    name   = "root-device-type"
    values = ["ebs"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  filter {
    name   = "tag:Consul-Version"
    values = ["${var.consul_version}"]
  }

  filter {
    name   = "tag:Nomad-Version"
    values = ["${var.nomad_version}"]
  }

  filter {
    name   = "tag:Vault-Version"
    values = ["${var.vault_version}"]
  }
}

resource "aws_iam_role" "hashistack_server" {
  name               = "${random_id.environment_name.hex}-HashiStack-Server"
  assume_role_policy = "${data.aws_iam_policy_document.assume_role.json}"
}

resource "aws_iam_role_policy" "hashistack_server" {
  name   = "SelfAssembly"
  role   = "${aws_iam_role.hashistack_server.id}"
  policy = "${data.aws_iam_policy_document.hashistack_server.json}"
}

resource "aws_iam_instance_profile" "hashistack_server" {
  name = "${random_id.environment_name.hex}-HashiStack-Server"
  role = "${aws_iam_role.hashistack_server.name}"
}

data "template_file" "init" {
  template = "${file("${path.module}/init-cluster.tpl")}"

  vars = {
    cluster_size     = "${var.cluster_size}"
    environment_name = "${random_id.environment_name.hex}"
  }
}

resource "aws_launch_configuration" "hashistack_server" {
  associate_public_ip_address = false
  ebs_optimized               = false
  iam_instance_profile        = "${aws_iam_instance_profile.hashistack_server.id}"
  image_id      = "${data.aws_ami.hashistack.id}"
  instance_type = "${var.instance_type}"
  user_data     = "${data.template_file.init.rendered}"
  key_name      = "${module.ssh-keypair-aws.ssh_key_name}"

  security_groups = [
    "${aws_security_group.hashistack_server.id}",
    "${aws_security_group.consul_client.id}",
  ]

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_autoscaling_group" "hashistack_server" {
  launch_configuration = "${aws_launch_configuration.hashistack_server.id}"
  vpc_zone_identifier  = ["${module.network-aws-simple.subnet_public_ids}"]
  name                 = "${random_id.environment_name.hex} HashiStack Servers"
  max_size             = "${var.cluster_size}"
  min_size             = "${var.cluster_size}"
  desired_capacity     = "${var.cluster_size}"
  default_cooldown     = 30
  force_delete         = true

  tag {
    key                 = "Name"
    value               = "${format("%s HashiStack Server", random_id.environment_name.hex)}"
    propagate_at_launch = true
  }

  tag {
    key                 = "Cluster-Name"
    value               = "${random_id.environment_name.hex}"
    propagate_at_launch = true
  }

  tag {
    key                 = "Environment-Name"
    value               = "${random_id.environment_name.hex}"
    propagate_at_launch = true
  }
}
