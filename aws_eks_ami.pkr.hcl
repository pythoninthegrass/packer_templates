#!/usr/bin/env packer build --force
#
#  Author: Hari Sekhon
#  Date: 2025-01-11 01:02:08 +0700 (Sat, 11 Jan 2025)
#
#  vim:ts=2:sts=2:sw=2:et:filetype=conf
#
#  https://github.com/HariSekhon/Templates
#
#  License: see accompanying Hari Sekhon LICENSE file
#
#  If you're using my code you're welcome to connect with me on LinkedIn and optionally send me feedback to help steer this or other code I publish
#
#  https://www.linkedin.com/in/HariSekhon
#

# ============================================================================ #
#                    P a c k e r   -   A W S   E K S   A M I
# ============================================================================ #

packer {
  required_version = ">= 1.7.0, < 2.0.0"
  required_plugins {
    amazon = {
      version = "~> 1.2"
      source  = "github.com/hashicorp/amazon"
    }
  }
}

locals {
  scripts    = "${path.root}/scripts"

  #timestamp        = regex_replace(timestamp(), "[- TZ:]", "")
  #timestamp        = regex_replace(timestamp(), "[ ]", "")
  #ami_target_name  = "amazon-eks-node-${var.eks_version}-al2-${local.timestamp}"
  ami_source_name  = "amazon-eks-node-${var.eks_version}-*"
  ami_source_owner = "602401143452"  # Amazon EKS AMI account ID
  ami_target_name  = "amazon-eks-node-${var.eks_version}-custom-{{timestamp}}"
  ami_description  = "EKS Kubernetes ${var.eks_version} Worker AMI (AmazonLinux2)"

  # locals can access data sources but data sources cannot access locals, to prevent circular dependencies
  #source_ami_id   = data.amazon-ami.ubuntu.id
  #ami_source_name = data.amazon-ami.ubuntu.name

  #value         = data.amazon-secretsmanager.NAME.value
  #secret_string = data.amazon-secretsmanager.NAME.secret_string
  #version_id    = data.amazon-secretsmanager.NAME.version_id
  #secret_value  = jsondecode(data.amazon-secretsmanager.NAME.secret_string)["packer_test_key"]

  tags = {
    App         = "MyApp"  # XXX: Edit and add relevant tags
    Environment = "Production"
    BuildDate   = "${timestamp()}"
  }

  crowdstrike_version = "7.17.0-17005"

  # requires AWS profile / access key to be found, else errors out
  #
  # set second arg to the key if secret had multiple keys, else set to null
  crowdstrike = aws_secretsmanager("crowdstrike", null)  # always pulls latest version AWSCURRENT, previous versions not supported

  #my_version = "${consul_key("myservice/version")}"

  # requires VAULT_TOKEN and VAULT_ADDR environment variables to be set
  #
  #foo2 = vault("/secret/data/hello", "foo")
}

variable "eks_version" {
  type        = string
  default     = "1.28"
	description = "Version of AWS EKS Kubernetes (important for Kubelet => Master compatibility)"
  validation {
    # regex(...) fails if it cannot find a match
    condition     = can(regex("^\\d+\\.\\d+$", var.eks_version))
    error_message = "EKS version not in expected '<int>.<int>' major.minor version format."
  }
}

variable "aws_region" {
  default = env("AWS_DEFAULT_REGION")
}

#variable "aws_packer_role" {
#  type    = string
#  default = ""
#}

variable "instance_type" {
  type = string
  default = "t3.micro"
}

variable "ami_source_arch" {
  type    = string
  default = "x86_64"
}

variable "ami_virtualization_type" {
  type    = string
  default = "hvm"
}

variable "ami_root_device_type" {
  type    = string
  default = "ebs"
}

#variable "iam_instance_profile" {
#  type    = string
#  default = "Packer"
#}

variable "encrypt_boot" {
  type    = bool
  default = false  # must set kms_key_id if true
}

variable "kms_key_id" {
  type    = string
  default = "Packer"
}

variable "subnet_id" {
  type    = string
  default = ""
}

variable "ssh_username" {
  type    = string
  default = "ec2-user"
}

variable "root_volume_size" {
  type    = string
  default = "100"  # GB
}

variable "volume_type" {
  type    = string
  default = "gp2"
}

#variable "availability_zone_names" {
#  type = list(string)
#  default = [
#    "eu-west-2a",
#    "eu-west-2b",
#    "eu-west-2c"
#  ]
#}

data "amazon-ami" "result" {
  assume_role = {
    external_id  = "EXTERNAL_ID"
    role_arn     = var.packer_role
    session_name = "Packer"
  }
  filters = {
    architecture        = var.ami_source_arch
    name                = local.ami_source_name
    root-device-type    = var.ami_root_device_type
    virtualization-type = var.ami_virtualization_type
    state               = "available"
  }
  most_recent = true
  #owners      = ["${var.ami_source_owner}", "${var.ami_source_owner_govcloud}"]
  owners      = [var.ami_source_owner]
  region      = "${var.aws_region}"
}

# https://developer.hashicorp.com/packer/integrations/hashicorp/amazon
# https://developer.hashicorp.com/packer/integrations/hashicorp/amazon/latest/components/data-source/ami
# https://developer.hashicorp.com/packer/integrations/hashicorp/amazon/latest/components/builder/ebs
source "amazon-ebs" "eks_ami" {
  #assume_role = {
  #  external_id  = "EXTERNAL_ID"
  #  role_arn     = var.aws_packer_role
  #  session_name = "Packer"
  #}
  #ami_name                = "eks-1-28-custom-ami-{{timestamp}}"
  ami_name                = local.ami_target_name
  ami_description         = local.ami_description
  ami_virtualization_type = var.ami_virtualization_type
  instance_type           = var.instance_type
  region                  = var.aws_region
  source_ami              = data.amazon-ami.result.id
  #source_ami_filter {
  #  filters = {
  #    name                = var.ami_source_name
  #    architecture        = var.ami_source_arch
  #    root-device-type    = var.ami_root_device_type
  #    virtualization-type = var.ami_virtualization_type
  #    state               = "available"
  #  }
  #  most_recent = true
  #  owners      = [
  #    "602401143452"  # Amazon EKS AMI account ID
  #    #"${var.source_ami_owner}", "${var.source_ami_owner_govcloud}"
  #    ]
  #}
  encrypt_boot            = var.encrypt_boot
  iam_instance_profile    = var.iam_instance_profile
  kms_key_id              = var.kms_key_id
  launch_block_device_mappings {
    delete_on_termination = true
    device_name           = "/dev/xvda"
    encrypted             = var.encrypt_boot
    kms_key_id            = var.ebs_kms_key
    volume_size           = var.root_volume_size
    volume_type           = var.volume_type
  }
  ssh_pty      = true
  #ssh_username = "packer"
  #ssh_password = "packer"
  ssh_username = var.ssh_username
  #subnet_id    = "<your-subnet-id>" # Optional: Specify a subnet if required
  subnet_id    = var.subnet_id
  ssh_timeout  = "30m" # default: 5m - waits 5 mins for SSH to come up otherwise kills VM
  # ensure filesystem is fsync'd
  #shutdown_command = "echo 'packer' | sudo -S shutdown -P now"
  # ec2-user should have passwordless sudo
  shutdown_command = "sudo -S shutdown -P now"
  tags = local.tags
}

build {
  name = "eks-${var.eks_version}-ami"

  sources = ["source.amazon-ebs.eks_ami"]

  provisioner "shell-local" {
    inline = [
      "env | grep PACKER || :",
      "echo Build UUID: ${build.PackerRunUUID}",
      "echo Source '${source.name}' type '${source.type}'",
    ]
  }

  # Download CrowdStrike RPM from pre-staged S3 bucket
  provisioner "shell-local" {
    script = "${local.scripts}/download_crowdstrike.sh"
    execute_command = "bash -euo pipefail '{{ .Path }}' '${local.crowdstrike_version}'"
    environment_vars = [
      "AWS_PROFILE=cicd",  # the profile that has the permissions to download the RPM
      "AWS_CONFIG_FILE=../../aws/cicd/config.ini"
    ]
  }

  # Upload CrowdStrike RPM to EC2 VM of AMI build
  provisioner "file" {
    source      = "falcon-sensor-${local.crowdstrike_version}.AmazonLinux-2.rpm"
    destination = "falcon-sensor-${local.crowdstrike_version}.AmazonLinux-2.rpm"
    direction   = "upload"
  }

  provisioner "file" {
    source      = "${local.scripts}/lib"
    destination = "/tmp/packer/lib"
  }

  provisioner "shell" {
    inline = [
      "echo OS:",
      "echo",
      "cat /etc/*release",
      "echo",
      "echo Environment:",
      "echo",
      "env | sort"
    ]
  }

  provisioner "shell" {
    inline = [
      "env | grep PACKER || :",
      "echo Build UUID: ${build.PackerRunUUID}",
      "echo Source '${source.name}' type '${source.type}'",
    ]
  }

  provisioner "shell" {
    scripts = [
      "${local.scripts}/yum_update_packages.sh",
      "${local.scripts}/install_aws_ssm_agent.sh",
      "${local.scripts}/install_auditd.sh",
      "${local.scripts}/configure_auditd_rsyslog_logserver.sh",
      "${local.scripts}/install_crowdstrike.sh",
      "${local.scripts}/install_eks_tools.sh",
      "${local.scripts}/final.sh"
    ]
    execute_command = "echo 'packer' | sudo -S -E bash -euo pipefail '{{ .Path }}'"
    # max_retries = 5
    # timeout = "5m"
  }

  post-processor "compress" {}

  # post-processor blocks run in parallel
  #
  post-processor "checksum" {               # checksum image
    checksum_types      = ["md5", "sha512"] # checksum the artifact
    keep_input_artifact = true              # keep the artifact
    output              = "output-{{.BuildName}}/{{.BuildName}}.{{.ChecksumType}}"  # default: packer_{{.BuildName}}_{{.BuilderType}}_{{.ChecksumType}}.checksum, at top level not in the directory with the .ova, and it keeps appending to it
  }
}
