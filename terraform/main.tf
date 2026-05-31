terraform {
  required_providers {
    yandex = {
      source  = "yandex-cloud/yandex"
      version = "0.130.0"
    }
  }

  required_version = ">= 1.0"
}

provider "yandex" {
  cloud_id  = "b1g7j1rd5da7r9q84j1"
  folder_id = "b1g9t1nrpau6sbh0alrg"
  zone      = "ru-central1-d"
}

locals {
  ssh_user = "ubuntu"
  ssh_key  = file("~/.ssh/id_ed25519_yc.pub")
}

data "yandex_compute_image" "ubuntu" {
  family    = "ubuntu-2204-lts"
  folder_id = "standard-images"
}

# -------------------------
# Network
# -------------------------

resource "yandex_vpc_network" "network" {
  name = "diplom-network"
}

resource "yandex_vpc_gateway" "nat_gateway" {
  name = "diplom-nat-gateway"

  shared_egress_gateway {}
}

resource "yandex_vpc_route_table" "private_route_table" {
  name       = "diplom-private-route-table"
  network_id = yandex_vpc_network.network.id

  static_route {
    destination_prefix = "0.0.0.0/0"
    gateway_id         = yandex_vpc_gateway.nat_gateway.id
  }
}

resource "yandex_vpc_subnet" "public_a" {
  name           = "diplom-public-a"
  zone           = "ru-central1-a"
  network_id     = yandex_vpc_network.network.id
  v4_cidr_blocks = ["10.10.10.0/24"]
}

resource "yandex_vpc_subnet" "public_b" {
  name           = "diplom-public-b"
  zone           = "ru-central1-b"
  network_id     = yandex_vpc_network.network.id
  v4_cidr_blocks = ["10.10.20.0/24"]
}

resource "yandex_vpc_subnet" "public_d" {
  name           = "diplom-public-d"
  zone           = "ru-central1-d"
  network_id     = yandex_vpc_network.network.id
  v4_cidr_blocks = ["10.10.30.0/24"]
}

resource "yandex_vpc_subnet" "private_a" {
  name           = "diplom-private-a"
  zone           = "ru-central1-a"
  network_id     = yandex_vpc_network.network.id
  route_table_id = yandex_vpc_route_table.private_route_table.id
  v4_cidr_blocks = ["10.10.110.0/24"]
}

resource "yandex_vpc_subnet" "private_b" {
  name           = "diplom-private-b"
  zone           = "ru-central1-b"
  network_id     = yandex_vpc_network.network.id
  route_table_id = yandex_vpc_route_table.private_route_table.id
  v4_cidr_blocks = ["10.10.120.0/24"]
}

resource "yandex_vpc_subnet" "private_d" {
  name           = "diplom-private-d"
  zone           = "ru-central1-d"
  network_id     = yandex_vpc_network.network.id
  route_table_id = yandex_vpc_route_table.private_route_table.id
  v4_cidr_blocks = ["10.10.130.0/24"]
}

# -------------------------
# Security Groups
# -------------------------

resource "yandex_vpc_security_group" "bastion_sg" {
  name       = "diplom-bastion-sg"
  network_id = yandex_vpc_network.network.id

  ingress {
    description    = "SSH from internet"
    protocol       = "TCP"
    port           = 22
    v4_cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    description    = "All outbound"
    protocol       = "ANY"
    v4_cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "yandex_vpc_security_group" "web_sg" {
  name       = "diplom-web-sg"
  network_id = yandex_vpc_network.network.id

  ingress {
    description       = "SSH from bastion"
    protocol          = "TCP"
    port              = 22
    security_group_id = yandex_vpc_security_group.bastion_sg.id
  }

  ingress {
    description    = "HTTP from ALB and internal network"
    protocol       = "TCP"
    port           = 80
    v4_cidr_blocks = ["10.10.0.0/16"]
  }

  ingress {
    description    = "Zabbix agent"
    protocol       = "TCP"
    port           = 10050
    v4_cidr_blocks = ["10.10.0.0/16"]
  }

  egress {
    description    = "All outbound"
    protocol       = "ANY"
    v4_cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "yandex_vpc_security_group" "zabbix_sg" {
  name       = "diplom-zabbix-sg"
  network_id = yandex_vpc_network.network.id

  ingress {
    description    = "SSH from internet"
    protocol       = "TCP"
    port           = 22
    v4_cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description    = "Zabbix web UI"
    protocol       = "TCP"
    port           = 80
    v4_cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description    = "Zabbix server"
    protocol       = "TCP"
    port           = 10051
    v4_cidr_blocks = ["10.10.0.0/16"]
  }

  egress {
    description    = "All outbound"
    protocol       = "ANY"
    v4_cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "yandex_vpc_security_group" "elasticsearch_sg" {
  name       = "diplom-elasticsearch-sg"
  network_id = yandex_vpc_network.network.id

  ingress {
    description       = "SSH from bastion"
    protocol          = "TCP"
    port              = 22
    security_group_id = yandex_vpc_security_group.bastion_sg.id
  }

  ingress {
    description    = "Elasticsearch from internal network"
    protocol       = "TCP"
    port           = 9200
    v4_cidr_blocks = ["10.10.0.0/16"]
  }

  ingress {
    description    = "Zabbix agent"
    protocol       = "TCP"
    port           = 10050
    v4_cidr_blocks = ["10.10.0.0/16"]
  }

  egress {
    description    = "All outbound"
    protocol       = "ANY"
    v4_cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "yandex_vpc_security_group" "kibana_sg" {
  name       = "diplom-kibana-sg"
  network_id = yandex_vpc_network.network.id

  ingress {
    description    = "SSH from internet"
    protocol       = "TCP"
    port           = 22
    v4_cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description    = "Kibana web UI"
    protocol       = "TCP"
    port           = 5601
    v4_cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description    = "Zabbix agent"
    protocol       = "TCP"
    port           = 10050
    v4_cidr_blocks = ["10.10.0.0/16"]
  }

  egress {
    description    = "All outbound"
    protocol       = "ANY"
    v4_cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "yandex_vpc_security_group" "alb_sg" {
  name       = "diplom-alb-sg"
  network_id = yandex_vpc_network.network.id

  ingress {
    description    = "HTTP from internet"
    protocol       = "TCP"
    port           = 80
    v4_cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    description    = "HTTP to web servers"
    protocol       = "TCP"
    port           = 80
    v4_cidr_blocks = ["10.10.0.0/16"]
  }
}

# -------------------------
# Compute instances
# -------------------------

resource "yandex_compute_instance" "bastion" {
  name        = "bastion"
  hostname    = "bastion"
  platform_id = "standard-v3"
  zone        = "ru-central1-d"

  resources {
    cores         = 2
    memory        = 2
    core_fraction = 20
  }

  scheduling_policy {
    preemptible = true
  }

  boot_disk {
    initialize_params {
      image_id = data.yandex_compute_image.ubuntu.id
      size     = 10
      type     = "network-hdd"
    }
  }

  network_interface {
    subnet_id          = yandex_vpc_subnet.public_d.id
    nat                = true
    security_group_ids = [yandex_vpc_security_group.bastion_sg.id]
  }

  metadata = {
    ssh-keys = "${local.ssh_user}:${local.ssh_key}"
  }
}

resource "yandex_compute_instance" "web_1" {
  name        = "web-1"
  hostname    = "web-1"
  platform_id = "standard-v3"
  zone        = "ru-central1-a"

  resources {
    cores         = 2
    memory        = 2
    core_fraction = 20
  }

  scheduling_policy {
    preemptible = true
  }

  boot_disk {
    initialize_params {
      image_id = data.yandex_compute_image.ubuntu.id
      size     = 10
      type     = "network-hdd"
    }
  }

  network_interface {
    subnet_id          = yandex_vpc_subnet.private_a.id
    nat                = false
    security_group_ids = [yandex_vpc_security_group.web_sg.id]
  }

  metadata = {
    ssh-keys = "${local.ssh_user}:${local.ssh_key}"
  }
}

resource "yandex_compute_instance" "web_2" {
  name        = "web-2"
  hostname    = "web-2"
  platform_id = "standard-v3"
  zone        = "ru-central1-b"

  resources {
    cores         = 2
    memory        = 2
    core_fraction = 20
  }

  scheduling_policy {
    preemptible = true
  }

  boot_disk {
    initialize_params {
      image_id = data.yandex_compute_image.ubuntu.id
      size     = 10
      type     = "network-hdd"
    }
  }

  network_interface {
    subnet_id          = yandex_vpc_subnet.private_b.id
    nat                = false
    security_group_ids = [yandex_vpc_security_group.web_sg.id]
  }

  metadata = {
    ssh-keys = "${local.ssh_user}:${local.ssh_key}"
  }
}

resource "yandex_compute_instance" "zabbix" {
  name        = "zabbix"
  hostname    = "zabbix"
  platform_id = "standard-v3"
  zone        = "ru-central1-d"

  resources {
    cores         = 2
    memory        = 4
    core_fraction = 20
  }

  scheduling_policy {
    preemptible = true
  }

  boot_disk {
    initialize_params {
      image_id = data.yandex_compute_image.ubuntu.id
      size     = 10
      type     = "network-hdd"
    }
  }

  network_interface {
    subnet_id          = yandex_vpc_subnet.public_d.id
    nat                = true
    security_group_ids = [yandex_vpc_security_group.zabbix_sg.id]
  }

  metadata = {
    ssh-keys = "${local.ssh_user}:${local.ssh_key}"
  }
}

resource "yandex_compute_instance" "elasticsearch" {
  name        = "elasticsearch"
  hostname    = "elasticsearch"
  platform_id = "standard-v3"
  zone        = "ru-central1-d"

  resources {
    cores         = 2
    memory        = 4
    core_fraction = 20
  }

  scheduling_policy {
    preemptible = true
  }

  boot_disk {
    initialize_params {
      image_id = data.yandex_compute_image.ubuntu.id
      size     = 15
      type     = "network-hdd"
    }
  }

  network_interface {
    subnet_id          = yandex_vpc_subnet.private_d.id
    nat                = false
    security_group_ids = [yandex_vpc_security_group.elasticsearch_sg.id]
  }

  metadata = {
    ssh-keys = "${local.ssh_user}:${local.ssh_key}"
  }
}

resource "yandex_compute_instance" "kibana" {
  name        = "kibana"
  hostname    = "kibana"
  platform_id = "standard-v3"
  zone        = "ru-central1-d"

  resources {
    cores         = 2
    memory        = 2
    core_fraction = 20
  }

  scheduling_policy {
    preemptible = true
  }

  boot_disk {
    initialize_params {
      image_id = data.yandex_compute_image.ubuntu.id
      size     = 10
      type     = "network-hdd"
    }
  }

  network_interface {
    subnet_id          = yandex_vpc_subnet.public_d.id
    nat                = true
    security_group_ids = [yandex_vpc_security_group.kibana_sg.id]
  }

  metadata = {
    ssh-keys = "${local.ssh_user}:${local.ssh_key}"
  }
}

# -------------------------
# Outputs
# -------------------------

output "bastion_external_ip" {
  value = yandex_compute_instance.bastion.network_interface[0].nat_ip_address
}

output "zabbix_external_ip" {
  value = yandex_compute_instance.zabbix.network_interface[0].nat_ip_address
}

output "kibana_external_ip" {
  value = yandex_compute_instance.kibana.network_interface[0].nat_ip_address
}

output "internal_fqdns" {
  value = {
    bastion       = "bastion.ru-central1.internal"
    web_1         = "web-1.ru-central1.internal"
    web_2         = "web-2.ru-central1.internal"
    zabbix        = "zabbix.ru-central1.internal"
    elasticsearch = "elasticsearch.ru-central1.internal"
    kibana        = "kibana.ru-central1.internal"
  }
}
