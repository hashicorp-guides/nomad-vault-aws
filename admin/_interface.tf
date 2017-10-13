# Optional variables
variable "environment_name_prefix" {
  default     = "vault-aws-auth"
  description = "Environment Name prefix eg my-hashistack-env"
}

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

variable "user" {
  default     = "ec2-user"
  description = "user: ec2-user/ubuntu, used by admin provisioner"
}

# Optional variables for the hashistack-aws repo
variable "cluster_size" {
  default     = "1"
  description = "Number of instances to launch in the cluster"
}

variable "consul_version" {
  default     = "0.9.2"
  description = "Consul version to use ie 0.9.3"
}

variable "nomad_version" {
  default     = "0.6.3"
  description = "Nomad version to use ie 0.6.3"
}

variable "vault_version" {
  default     = "0.8.3"
  description = "Vault version to use ie 0.8.3"
}

variable "region" {
  default     = "us-west-1"
  description = "Region to deploy consul cluster ie us-west-1"
}

## Outputs

output "ssh_info" {
  value = "${data.template_file.format_ssh.rendered}"
}

output "admin_ip" {
  value = "${aws_instance.vault_aws_auth_admin.public_dns}"
}
