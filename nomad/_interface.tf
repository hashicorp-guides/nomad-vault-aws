# Optional variables
variable "environment_name_prefix" {
  default     = "nomad"
  description = "Environment Name prefix eg my-nomad-env"
}

variable "cluster_size" {
  default     = "3"
  description = "Number of instances to launch in the cluster"
}

variable "consul_as_server" {
  default     = "false"
  description = "Run the consul agent in server mode: true/false"
}

variable "consul_version" {
  default     = "0.8.4"
  description = "Consul version to use eg 0.8.4"
}

variable "nomad_as_client" {
  default     = "true"
  description = "Run Nomad in client mode: true/false"
}

variable "nomad_as_server" {
  default     = "true"
  description = "Run Nomad in server mode: true/false"
}

variable "nomad_version" {
  default     = "0.6.0"
  description = "Nomad version to use eg 0.6.0"
}

variable "instance_type" {
  default     = "t2.micro"
  description = "AWS instance type to use eg m4.large"
}

variable "os" {
  # case sensitive for AMI lookup
  default     = "Ubuntu"
  description = "Operating System to use ie RHEL or Ubuntu"
}

variable "os_version" {
  default     = "16.04"
  description = "Operating System version to use ie 7.3 (for RHEL) or 16.04 (for Ubuntu)"
}

# Outputs

output "ssh_key_name" {
  value = "${data.terraform_remote_state.vault.ssh_key_name}"
}

output "iam_instance_profile_nomad_server" {
  value = "${module.nomad-aws.iam_instance_profile_nomad_server}"
}

output "subnet_public_ids" {
  value = "${data.terraform_remote_state.vault.subnet_public_ids}"
}
