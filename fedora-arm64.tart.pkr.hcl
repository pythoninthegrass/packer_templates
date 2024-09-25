packer {
  required_version = ">= 1.7.0, < 2.0.0"
  required_plugins {
    tart = {
      version = ">= 1.3.0"
      source  = "github.com/cirruslabs/tart"
    }
  }
}

variable "version" {
  type    = string
  default = "40"
}

variable "iso" {
  type    = string
  default = "Fedora-Server-dvd-aarch64-40-1.14.iso"
}

# TODO: debug 'VM "isos/fedora-40_cidata.iso:latest" does not exist
locals {
  name = "fedora"
  isos = [
    "isos/fedora-${var.version}_cidata.iso",
    "isos/${var.iso}"
  ]
  vm_name = "${local.name}-${var.version}"
}

source "tart-cli" "fedora" {
  vm_name      = local.vm_name
  from_iso     = local.isos
  cpu_count    = 4
  memory_gb    = 4
  disk_size_gb = 40
  # need to mount /cdrom but device not found
  boot_command = [
    "<wait3s><up><wait>",
    "e",
    "<down><down><down><left>",
    # leave a space from last arg
    " inst.ks=file:///cdrom/anaconda-ks.cfg <f10>",
    # go to terminal tty2 for CLI
    # XXX: this Alt-F2 keystroke is coming out unrecognized - https://github.com/cirruslabs/packer-plugin-tart/issues/71
    "<leftAltOn><f2><leftAltOff><wait2s>",
    # 'Press enter to activate this console' - drops into a Busybox shell
    "<enter><wait>",
    "mkdir /mnt/cdrom<enter>",
    "mkdir /mnt/cdrom2<enter>",
    "mount /dev/vdc1 /mnt/cdrom<enter>",
    # without '-t iso9660' gets unintuitive error 'mount: mounting /dev/vdb on /mnt/cdrom2 failed: Invalid argument''
    "mount -t iso9660 /dev/vdb /mnt/cdrom2<enter>",
    # go back to tty1
    # XXX: this Alt-F1 keystroke is coming out unrecognized
    "<leftAltOn><f1><leftAltOff>",
    # TODO: rest of keystrokes once F2 issue is resolved
  ]
  ssh_timeout  = "30m"
  ssh_username = "packer"
  ssh_password = "packer"
}

build {
  name = local.name
  sources = ["source.tart-cli.fedora"]

  provisioner "shell-local" {
    script = "./scripts/local_virtiofs.sh"
  }

  provisioner "shell" {
    scripts = [
      "./scripts/version.sh",
      "./scripts/mount_apple_virtiofs.sh",
      "./scripts/collect_anaconda.sh",
      "./scripts/final.sh",
    ]
    execute_command = "echo 'packer' | sudo -S -E bash '{{ .Path }}' '${packer.version}'"
  }

  post-processor "checksum" {
    checksum_types      = ["md5", "sha512"]
    keep_input_artifact = true
    output              = "output-{{.BuildName}}/{{.BuildName}}.{{.ChecksumType}}"
  }
}
