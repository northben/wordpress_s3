packer {
  required_plugins {
    docker = {
      version = ">= 0.0.7"
      source  = "github.com/hashicorp/docker"
    }
  }
}

variable "base_image" {
  type    = string
  default = "wordpress:php8.0-apache"
}

variable "this_image" {
  type    = string
  default = "wordpress_bgn"
}

variable "aws_profile" {
  type = string
}
variable "aws_ecr_repository" {
  type = string
}

source "docker" "this" {
  image  = var.base_image
  commit = true
  pull   = true
  changes = [
    "ENTRYPOINT [\"docker-entrypoint.sh\"]",
    "CMD [\"apache2-foreground\"]",
  ]
}

build {
  name = var.this_image
  sources = [
    "source.docker.this",
  ]

  provisioner "file" {
    source      = "{{ pwd }}/packer/files/uploads.ini"
    destination = "/tmp/"
  }
  provisioner "shell" {
    inline = [
      "mv /tmp/uploads.ini /usr/local/etc/php/conf.d/uploads.ini",
    ]
  }
  provisioner "file" {
    source      = "{{ pwd }}/packer/wordpress_modules/amazon-s3-and-cloudfront"
    destination = "/tmp/"
  }
  provisioner "shell" {
    inline = [
      "mv /tmp/amazon-s3-and-cloudfront /usr/src/wordpress/wp-content/plugins/",
    ]
  }
  provisioner "shell" {
    inline = [
      "cd /usr/src/wordpress",
      "cp -s wp-config-docker.php wp-config.php",
    ]
  }
  post-processor "docker-tag" {
    repository = var.this_image
    tags       = ["latest"]
  }
  post-processors {
    post-processor "docker-tag" {
      repository = "${var.aws_ecr_repository}/wordpress"
      tags       = ["latest"]
    }

    post-processor "docker-push" {
      ecr_login           = true
      aws_profile         = var.aws_profile
      login_server        = "${var.aws_ecr_repository}"
      keep_input_artifact = false
    }
  }
}
