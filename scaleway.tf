#the following refers to commercial_type found at https://developer.scaleway.com/#servers-servers-post
variable "commercial_type" {
  default = "START1-S"
  description = "Scaleway Instance"
}

variable "architectures" {
  default = {
    START1-S = "x86_64"
  }
}

data "scaleway_image" "ubuntux" {
  architecture = "${lookup(var.architectures, var.commercial_type)}"
  name = "Ubuntu Xenial"
}
# both give the same result
data "scaleway_image" "ubuntu" {
  architecture = "x86_64"
  name = "Ubuntu Xenial"
  most_recent = true
}

provider "scaleway" {
  region = "ams1"
#  version = "0.1"
}

resource "scaleway_security_group" "testendpoint" {
  name = "testendpoint"
  description = "allow testendpoint"
}

resource "scaleway_security_group_rule" "testendpoint_http_accept" {
  security_group = "${scaleway_security_group.testendpoint.id}"
  action = "accept"
  direction = "inbound"
  ip_range = "0.0.0.0/0"
  protocol = "TCP"
  port = 8000
}

variable "sec_group" {
  default = "testendpoint" #"${scaleway_security_group.testendpoint.name}"
}

resource "scaleway_server" "tf1" {
  name = "tf1"
  type = "${var.commercial_type}"
  dynamic_ip_required = true
#  security_group = "${var.sec_group}"
  image = "${data.scaleway_image.ubuntu.id}"
  
  provisioner "remote-exec" {
#    scripts = [
#      "server_install.sh"
#    ]
    inline = [
      "date > /remote-exec-test.txt"
    ]
  }
  provisioner "local-exec" {
    command = "date > /tmp/done-time-saved-on-local-machine.txt"
  }
}

resource "scaleway_ip" "tf1" {
  server = "${scaleway_server.tf1.id}"
}

output "public_ip" {
  value = "${scaleway_ip.tf1.ip}"
}

