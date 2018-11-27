# Find Public IP
data "http" "whatismyip" {
  url = "http://whatismyip.akamai.com/"
}

# Begin Variables 
variable "aws_ami" {
  description = "AMI to use"
  default     = "ami-4bf3d731"
}

variable "cluster_name" {
  description = "Name of your DC/OS Cluster"
  default     = "dcos-ansible"
}

variable "num_masters" {
  description = "Number of Masters"
  default     = "1"
}

variable "num_private_agents" {
  description = "Number of Private Agents"
  default     = "1"
}

variable "num_public_agents" {
  description = "Number of Public Agents"
  default     = "1"
}

variable "ssh_public_key_file" {
  description = "SSH Key Location"
  default     = "~/.ssh/id_rsa.pub"
}

# Begin Modules
module "dcos-infrastructure" {
  source              = "dcos-terraform/infrastructure/aws"
  admin_ips           = ["${data.http.whatismyip.body}/32"]
  aws_ami             = "${var.aws_ami}"
  cluster_name        = "${var.cluster_name}"
  num_masters         = "${var.num_masters}"
  num_private_agents  = "${var.num_private_agents}"
  num_public_agents   = "${var.num_public_agents}"
  ssh_public_key_file = "${var.ssh_public_key_file}"
}

module "dcos-ansible-bridge" {
  source               = "dcos-terraform/dcos-ansible-bridge/localfile"
  bootstrap_ip         = "${module.dcos-infrastructure.bootstrap.public_ip}"
  master_ips           = ["${module.dcos-infrastructure.masters.public_ips}"]
  private_agent_ips    = ["${module.dcos-infrastructure.private_agents.public_ips}"]
  public_agent_ips     = ["${module.dcos-infrastructure.public_agents.public_ips}"]
  bootstrap_private_ip = "${module.dcos-infrastructure.bootstrap.private_ip}"
  master_private_ips   = ["${module.dcos-infrastructure.masters.private_ips}"]
}

# Begin Outputs
output "bootstraps" {
  description = "bootsrap IPs"
  value       = "${join("\n", flatten(list(module.dcos-infrastructure.bootstrap.public_ip)))}"
}

output "bootstrap_private_ip" {
  description = "bootsrap IPs"
  value       = "${module.dcos-infrastructure.bootstrap.private_ip}"
}

output "masters" {
  description = "masters IPs"
  value       = "${join("\n", flatten(list(module.dcos-infrastructure.masters.public_ips)))}"
}

output "masters_private_ips" {
  description = "List of private IPs for Masters (for DCOS config)"
  value       = "${join("\n", flatten(list(module.dcos-infrastructure.masters.private_ips)))}"
}

output "private_agents" {
  description = "Private Agents IPs"
  value       = "${join("\n", flatten(list(module.dcos-infrastructure.private_agents.public_ips)))}"
}

output "public_agents" {
  description = "Public Agents IPs"
  value       = "${join("\n", flatten(list(module.dcos-infrastructure.public_agents.public_ips)))}"
}

# Locals
locals {
  bootstrap_ansible_ips         = "${join("\n", flatten(list(module.dcos-infrastructure.bootstrap.public_ip)))}"
  bootstrap_ansible_private_ips = "${module.dcos-infrastructure.bootstrap.private_ip}"
  masters_ansible_ips           = "${join("\n", flatten(list(module.dcos-infrastructure.masters.public_ips)))}"
  masters_ansible_private_ips   = "${join("\n - ", flatten(list(module.dcos-infrastructure.masters.private_ips)))}"
  private_agents_ansible_ips    = "${join("\n", flatten(list(module.dcos-infrastructure.private_agents.public_ips)))}"
  public_agents_ansible_ips     = "${join("\n", flatten(list(module.dcos-infrastructure.public_agents.public_ips)))}"
}

# Build the vars file
resource "local_file" "vars_file" {
  filename = "./group_vars/all/dcos.yaml"

  content = <<EOF
---
dcos:
  download: "https://downloads.dcos.io/dcos/stable/dcos_generate_config.sh"
  version: "1.12.0"
  version_to_upgrade_from: "1.12.0-dev"
  enterprise_dcos: false
  selinux_mode: enforcing

  config:
    cluster_name: "${var.cluster_name}"
    security: permissive
    bootstrap_url: http://${local.bootstrap_ansible_private_ips}:8080
    exhibitor_storage_backend: static
    master_discovery: static
    master_list:
      - ${local.masters_ansible_private_ips}
EOF
}
