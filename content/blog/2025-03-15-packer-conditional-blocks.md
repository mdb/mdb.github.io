---
title: "Packer: conditionally omit HCL block configuration"
date: 2025-03-15
tags:
- packer
- iac
thumbnail: cloud2_thumb.jpg
teaser: Conditionally configure AWS EC2 launch block device mappings in a Packer template.
intro: A not-too-complicated but suprisingly-hard-to-Google solution to a not-unusual need.
---

## Problem

You're using [Packer](https://www.packer.io/) to build [AWS EC2 AMIs](https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/AMIs.html). How can you
parameterize builds to conditionally configure or omit [amazon-ebs.launch_block_device_mappings](https://developer.hashicorp.com/packer/integrations/hashicorp/amazon/latest/components/builder/ebs#ebs-specific-configuration-reference)
based on the value of an [input variable](https://developer.hashicorp.com/packer/guides/hcl/variables)?

## Solution

Leverage [dynamic blocks](https://developer.hashicorp.com/packer/docs/templates/hcl_templates/expressions#dynamic-blocks); based on an input variable value, pass a `for_each` argument with a length of 0 to omit the configuration of `launch_block_device_mappings`.

## Example

For example, the following Packer template supports a `create_nonroot_devices`
input variable. By default, its value is `false`; `packer build` results in an AMI
with no nonroot `launch_block_device_mappings`:

```hcl
packer {
  required_version = ">= 1"

  required_plugins {
    amazon = {
      version = ">= 1.2.5"
      source  = "github.com/hashicorp/amazon"
    }
  }
}

variable "create_nonroot_devices" {
  type        = bool
  default     = false
  description = "Whether or not to create nonroot launch_block_device_mappings."
}

locals {
  timestamp = formatdate("YYYY-MM-DD-hhmmss-ZZZ", timestamp())
  name      = "foo-${local.timestamp}"

  # If var.create_nonroot_devices is true, configures a /dev/xvdf
  # launch_block_device_mapping. Otherwise, omit its creation.
  nonroot_devices = var.create_nonroot_devices ? ["/dev/xvdf"] : []
}

source "amazon-ebs" "foo" {
  region = "us-west-2"

  instance_type = "m6i.4xlarge"

  source_ami_filter {
    filters = {
      virtualization-type = "hvm"
      name                = "ubuntu/images/hvm-ssd/ubuntu-focal-22.04-amd64-server-*"
      root-device-type    = "ebs"
    }

    owners      = ["099720109477"]
    most_recent = true
  }

  ami_name        = local.name
  ami_description = "My AMI"

  tags = {
    Name = local.name
  }

  # root device
  launch_block_device_mappings {
    device_name           = "/dev/sda1"
    delete_on_termination = true
    encrypted             = true
    volume_type           = "gp3"
    volume_size           = 200
  }

  # conditionally create non root block device mappings
  dynamic "launch_block_device_mappings" {
    for_each = local.nonroot_devices

    content {
      device_name           = each.value
      delete_on_termination = true
      encrypted             = true
      volume_type           = "gp3"
      volume_size           = 200
    }
  }
}

build {
  sources = ["source.amazon-ebs.foo"]

  post-processor "manifest" {
    output = "manifest.json"
  }
}
```

To build an AMI with a nonroot `/dev/xvdf`, override `var.create_nonroot_devices`
with `true` at `packer build` time:

```
packer build \
  -var "create_nonroot_devices=true"
```
