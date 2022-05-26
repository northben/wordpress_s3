source "null" "download" {
  communicator = "none"
}

variable "plugin_download_url" {
  type = string
}

build {
#   name = "roles"

  sources = ["source.null.download"]
  provisioner "shell-local" {
    inline = [
      "if [ ! -e {{ pwd }}/packer/wordpress_modules/amazon-s3-and-cloudfront.zip ]; then wget -O {{ pwd }}/packer/wordpress_modules/amazon-s3-and-cloudfront.zip ${var.plugin_download_url}; fi",
      "cd packer/wordpress_modules",
      "unzip amazon-s3-and-cloudfront.zip",
    ]
  }
}
