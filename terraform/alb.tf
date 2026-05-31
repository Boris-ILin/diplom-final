resource "yandex_alb_target_group" "web_target_group" {
  name = "web-target-group"

  target {
    subnet_id  = yandex_vpc_subnet.private_a.id
    ip_address = yandex_compute_instance.web_1.network_interface[0].ip_address
  }

  target {
    subnet_id  = yandex_vpc_subnet.private_b.id
    ip_address = yandex_compute_instance.web_2.network_interface[0].ip_address
  }
}

resource "yandex_alb_backend_group" "web_backend_group" {
  name = "web-backend-group"

  http_backend {
    name             = "web-backend"
    weight           = 1
    port             = 80
    target_group_ids = [yandex_alb_target_group.web_target_group.id]

    load_balancing_config {
      panic_threshold = 50
    }

    healthcheck {
      timeout             = "2s"
      interval            = "5s"
      healthy_threshold   = 2
      unhealthy_threshold = 2
      healthcheck_port    = 80

      http_healthcheck {
        path = "/"
      }
    }
  }
}

resource "yandex_alb_http_router" "web_http_router" {
  name = "web-http-router"
}

resource "yandex_alb_virtual_host" "web_virtual_host" {
  name           = "web-virtual-host"
  http_router_id = yandex_alb_http_router.web_http_router.id

  route {
    name = "web-route"

    http_route {
      http_route_action {
        backend_group_id = yandex_alb_backend_group.web_backend_group.id
      }
    }
  }
}

resource "yandex_alb_load_balancer" "web_alb" {
  name               = "web-alb"
  network_id         = yandex_vpc_network.network.id
  security_group_ids = [yandex_vpc_security_group.alb_sg.id]

  allocation_policy {
    location {
      zone_id   = "ru-central1-a"
      subnet_id = yandex_vpc_subnet.public_a.id
    }

    location {
      zone_id   = "ru-central1-b"
      subnet_id = yandex_vpc_subnet.public_b.id
    }

    location {
      zone_id   = "ru-central1-d"
      subnet_id = yandex_vpc_subnet.public_d.id
    }
  }

  listener {
    name = "http-listener"

    endpoint {
      address {
        external_ipv4_address {}
      }

      ports = [80]
    }

    http {
      handler {
        http_router_id = yandex_alb_http_router.web_http_router.id
      }
    }
  }
}

output "alb_ip_address" {
  description = "Public IP address of Application Load Balancer"
  value       = yandex_alb_load_balancer.web_alb.listener[0].endpoint[0].address[0].external_ipv4_address[0].address
}
