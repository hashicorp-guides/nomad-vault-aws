terraform {
  required_version = ">= 0.9.3"
}

data "terraform_remote_state" "vault" {
  backend = "local"
  config {
    path = "${path.module}/../vault/vault.tfstate"
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
  cluster_name     = "nomad-vault-consul-asg"
  cluster_size     = "${var.cluster_size}"
  consul_version   = "${var.consul_version}"
  environment_name = "nomad-vault-aws"
  instance_type    = "${var.instance_type}"
  os               = "${var.os}"
  os_version       = "${var.os_version}"
  ssh_key_name     = "${module.ssh-keypair-aws.ssh_key_name}"
  subnet_ids       = "${data.terraform_remote_state.vault.subnet_public_ids}"
  vpc_id           = "${data.terraform_remote_state.vault.vpc_id}"
}

module "nomad-aws" {
  //source              = "github.com/hashicorp-modules/nomad-aws?ref=0.1.0"
  source              = "../../../modules/nomad-aws"
  cluster_name        = "nomad-vault-nomad-asg"
  cluster_size        = "${var.cluster_size}"
  consul_server_sg_id = "${module.consul-aws.consul_server_sg_id}"
  consul_as_server    = "${var.consul_as_server}"
  environment_name    = "nomad-vault-aws"
  nomad_as_client     = "${var.nomad_as_client}"
  nomad_as_server     = "${var.nomad_as_server}"
  nomad_version       = "${var.nomad_version}"
  instance_type       = "${var.instance_type}"
  os                  = "${var.os}"
  os_version          = "${var.os_version}"
  ssh_key_name        = "${module.ssh-keypair-aws.ssh_key_name}"
  subnet_ids       = "${data.terraform_remote_state.vault.subnet_public_ids}"
  vpc_id           = "${data.terraform_remote_state.vault.vpc_id}"
}
