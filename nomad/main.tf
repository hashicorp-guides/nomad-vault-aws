terraform {
  required_version = ">= 0.9.3"
}

data "terraform_remote_state" "vault" {
  backend = "local"
  config {
    path = "${path.module}/../vault/vault.tfstate"
  }
}

module "nomad-aws" {
  source              = "github.com/hashicorp-modules/nomad-aws?ref=0.1.0"
  //source              = "../../nomad-aws"
  cluster_name        = "${data.terraform_remote_state.vault.environment_name}"
  cluster_size        = "${var.cluster_size}"
  consul_server_sg_id = "${data.terraform_remote_state.vault.consul_client_sg_id}"
  consul_as_server    = "${var.consul_as_server}"
  environment_name    = "${data.terraform_remote_state.vault.environment_name}"
  nomad_as_client     = "${var.nomad_as_client}"
  nomad_as_server     = "${var.nomad_as_server}"
  nomad_version       = "${var.nomad_version}"
  instance_type       = "${var.instance_type}"
  os                  = "${var.os}"
  os_version          = "${var.os_version}"
  ssh_key_name        = "${data.terraform_remote_state.vault.ssh_key_name}"
  subnet_ids          = "${data.terraform_remote_state.vault.subnet_public_ids}"
  vpc_id              = "${data.terraform_remote_state.vault.vpc_id}"
  #vault_enabled       = "${var.vault_enabled}"
}
