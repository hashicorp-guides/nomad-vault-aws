terraform {
  backend "atlas" {
    name    = "aklaas/nomad-aws"
    address = "https://atlas.hashicorp.com"
  }
}

resource "random_id" "environment_name" {
  byte_length = 4
  prefix      = "${var.environment_name_prefix}-"
}

module "network-aws" {
  source           = "github.com/hashicorp-modules/network-aws?ref=0.1.0"
  environment_name = "${random_id.environment_name.hex}"
  os               = "${var.os}"
  os_version       = "${var.os_version}"
  ssh_key_name     = "${module.ssh-keypair-aws.ssh_key_name}"
}

module "ssh-keypair-aws" {
  source       = "github.com/hashicorp-modules/ssh-keypair-aws?ref=0.1.0"
  ssh_key_name = "${random_id.environment_name.hex}"
}

module "consul-aws" {
  source           = "github.com/hashicorp-modules/consul-aws?ref=0.1.0"
  cluster_name     = "${random_id.environment_name.hex}-consul-asg"
  cluster_size     = "${var.cluster_size}"
  consul_version   = "${var.consul_version}"
  environment_name = "${random_id.environment_name.hex}"
  instance_type    = "${var.instance_type}"
  os               = "${var.os}"
  os_version       = "${var.os_version}"
  ssh_key_name     = "${module.ssh-keypair-aws.ssh_key_name}"
  subnet_ids       = "${module.network-aws.subnet_private_ids}"
  vpc_id           = "${module.network-aws.vpc_id}"
}

module "nomad-aws" {
  //source              = "github.com/hashicorp-modules/nomad-aws?ref=0.1.0"
  source              = "../../../modules/nomad-aws"
  cluster_name        = "${random_id.environment_name.hex}-nomad-asg"
  cluster_size        = "${var.cluster_size}"
  consul_server_sg_id = "${module.consul-aws.consul_server_sg_id}"
  consul_as_server    = "${var.consul_as_server}"
  environment_name    = "${random_id.environment_name.hex}"
  nomad_as_client     = "${var.nomad_as_client}"
  nomad_as_server     = "${var.nomad_as_server}"
  nomad_version       = "${var.nomad_version}"
  instance_type       = "${var.instance_type}"
  os                  = "${var.os}"
  os_version          = "${var.os_version}"
  ssh_key_name        = "${module.ssh-keypair-aws.ssh_key_name}"
  subnet_ids          = "${module.network-aws.subnet_public_ids}"
  vpc_id              = "${module.network-aws.vpc_id}"
}
