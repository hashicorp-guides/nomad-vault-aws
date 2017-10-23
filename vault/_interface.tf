# Required variables
/*
variable "cluster_name" {
  description = "Auto Scaling Group Cluster Name"
}

variable "environment_name" {
  description = "Environment Name (tagged to all instances)"
}
*/

# Required variables for hashistack-aws config
variable "os" {
  # case sensitive for AMI lookup
  default     = "RHEL"
  description = "Operating System to use ie RHEL or Ubuntu"
}

variable "os_version" {
  default     = "7.3"
  description = "Operating System version to use ie 7.3 (for RHEL) or 16.04 (for Ubuntu)"
}

variable "region" {
  default     = "us-west-1"
  description = "Region to deploy consul cluster ie us-west-1"
}

variable "consul_version" {
  default     = "0.9.2"
  description = "Consul version to use ie 0.8.4"
}

variable "nomad_version" {
  default     = "0.6.3"
  description = "Nomad version to use ie 0.6.0"
}

variable "vault_version" {
  default     = "0.8.3"
  description = "Vault version to use ie 0.7.1"
}

/*
variable "ssh_key_name" {
  description = "Pre-existing AWS key name you will use to access the instance(s)"
}

variable "subnet_ids" {
  type        = "list"
  description = "Pre-existing Subnet ID(s) to use"
}

variable "vpc_id" {
  description = "Pre-existing VPC ID to use"
}
*/

# Optional variables
variable "environment_name_prefix" {
  default     = "nomad-vault"
  description = "Environment Name prefix eg my-hashistack-env"
}

variable "cluster_size" {
  default     = "3"
  description = "Number of instances to launch in the cluster"
}

variable "environment" {
  default     = "production"
  description = "Environment eg development, stage or production"
}

variable "instance_type" {
  default     = "m4.large"
  description = "AWS instance type to use eg m4.large"
}

## Outputs

# network-aws outputs
output "vpc_id" {
  value = "${module.network-aws-simple.vpc_id}"
}

output "subnet_public_ids" {
  value = ["${module.network-aws-simple.subnet_public_ids}"]
}

output "security_group_egress_id" {
  value = "${module.network-aws-simple.security_group_apps}"
}

# hashistack-aws outputs
output "hashistack_autoscaling_group_id" {
  value = "${aws_autoscaling_group.hashistack_server.id}"
}

output "consul_client_sg_id" {
  value = "${aws_security_group.consul_client.id}"
}

output "hashistack_server_sg_id" {
  value = "${aws_security_group.hashistack_server.id}"
}

output "environment_name" {
  value = "${random_id.environment_name.hex}"
}

# ssh-keypair-aws outputs
# Uncomment below to output private key contents
output "private_key_data" {
  value = "${module.ssh-keypair-aws.private_key_data}"
}

output "ssh_key_name" {
  value = "${module.ssh-keypair-aws.ssh_key_name}"
}
