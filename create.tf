provider "google" {
    credentials = "${file("stage_key.json")}"
    project = "stage-263008"
    region = "europe-west3"
}

resource "google_compute_firewall" "external_ports" {
    name = "vpn-external-ports"
    network = "default"

    allow {
        protocol = "udp"
        ports = ["1194"]
    }
}

resource "google_compute_instance" "vpn-server" {
    name = "vpn-server"
    machine_type = "f1-micro"
    zone = "europe-west3-a"

    connection {
        host = "${self.network_interface.0.access_config.0.nat_ip}"
        type = "ssh"
        user = "jerrye"
        agent = false
        private_key = "${file("~/.ssh/id_rsa")}"
    }

    boot_disk {
        initialize_params {
            image = "centos-cloud/centos-7"
        }
    }

    network_interface {
        network = "default"
        access_config {}
    }

    metadata = {
        ssh-keys = "jerrye:${file("~/.ssh/id_rsa.pub")}"
    }

    provisioner "file" {
        source = "${path.module}/deploy.yml"
        destination = "/tmp/deploy.yml"
    }

    provisioner "remote-exec" {
        inline = [
            "sudo yum install -y python-pip",
            "sudo pip install ansible",
            "ansible-playbook /tmp/deploy.yml"
        ]
    }
}

# resource "google_dns_managed_zone" "vpn-zone" {
#     name = "vpn-zone"
#     dns_name = "vpn.vodomat.net."
# }

# resource "google_dns_record_set" "vpn-server" {
#     name = "server.vpn.vodomat.net."
#     type = "A"
#     ttl = 300
#     managed_zone = "${google_dns_managed_zone.vpn-zone.name}"
#     rrdatas = ["${google_compute_instance.vpn-server.network_interface.0.access_config.0.nat_ip}"]
# }

output "vpn_external_ip" {
    value = "${google_compute_instance.vpn-server.network_interface.0.access_config.0.nat_ip}"
}
