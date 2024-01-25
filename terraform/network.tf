#network

resource "yandex_vpc_network" "vpc" {
  name = "vpc"
}

#nat gateway  

resource "yandex_vpc_gateway" "nat_gateway" {
  name = "gateway"
  shared_egress_gateway {}
}

resource "yandex_vpc_route_table" "route_table" {
  network_id = yandex_vpc_network.vpc.id

  static_route {
    destination_prefix = "0.0.0.0/0"
    gateway_id         = yandex_vpc_gateway.nat_gateway.id
  }
}

#private subnet for website1

resource "yandex_vpc_subnet" "private-subnet-1" {
  name = "private-subnet-1"

  v4_cidr_blocks = ["192.168.10.0/24"]
  zone           = "ru-central1-a"
  network_id     = yandex_vpc_network.vpc.id
  route_table_id = yandex_vpc_route_table.route_table.id
}

#private subnet for website2

resource "yandex_vpc_subnet" "private-subnet-2" {
  name = "private-subnet-2"

  v4_cidr_blocks = ["192.168.20.0/24"]
  zone           = "ru-central1-b"
  network_id     = yandex_vpc_network.vpc.id
  route_table_id = yandex_vpc_route_table.route_table.id
}


#private subnet for elasticsearch

resource "yandex_vpc_subnet" "private-subnet-3" {
  name = "private-subnet-3"

  v4_cidr_blocks = ["192.168.30.0/24"]
  zone           = "ru-central1-c"
  network_id     = yandex_vpc_network.vpc.id
  route_table_id = yandex_vpc_route_table.route_table.id
}

#public subnet for zabbix kibana

resource "yandex_vpc_subnet" "public-subnet" {
  name = "public-subnet"

  v4_cidr_blocks = ["192.168.40.0/24"]
  zone           = "ru-central1-c"
  network_id     = yandex_vpc_network.vpc.id
}

#public subnet for bastion

resource "yandex_vpc_subnet" "public-bastion-subnet" {
  name = "public-bastion-subnet"

  v4_cidr_blocks = ["192.168.50.0/24"]
  zone           = "ru-central1-c"
  network_id     = yandex_vpc_network.vpc.id
}

#target Group

resource "yandex_alb_target_group" "tg-group" {
  name = "tg-group"

  target {
    ip_address = yandex_compute_instance.website1.network_interface.0.ip_address
    subnet_id  = yandex_vpc_subnet.private-subnet-1.id
  }

  target {
    ip_address = yandex_compute_instance.website2.network_interface.0.ip_address
    subnet_id  = yandex_vpc_subnet.private-subnet-2.id
  }
}

#backend Group

resource "yandex_alb_backend_group" "backend-group" {
  name = "backend-group"

  http_backend {
    name             = "backend"
    weight           = 1
    port             = 80
    target_group_ids = [yandex_alb_target_group.tg-group.id]
    load_balancing_config {
      panic_threshold = 90
    }
    healthcheck {
      timeout             = "10s"
      interval            = "2s"
      healthy_threshold   = 10
      unhealthy_threshold = 15
      http_healthcheck {
        path = "/"
      }
    }
  }
}

#HTTP router

resource "yandex_alb_http_router" "router" {
  name = "router"
}

resource "yandex_alb_virtual_host" "router-host" {
  name           = "router-host"
  http_router_id = yandex_alb_http_router.router.id
  route {
    name = "route"
    http_route {
      http_match {
        path {
          prefix = "/"
        }
      }
      http_route_action {
        backend_group_id = yandex_alb_backend_group.backend-group.id
        timeout          = "3s"
      }
    }
  }
}

#application load balancer

resource "yandex_alb_load_balancer" "load-balancer" {
  name               = "load-balancer"
  network_id         = yandex_vpc_network.vpc.id
  security_group_ids = [yandex_vpc_security_group.load-balancer-sg.id]

  allocation_policy {
    location {
      zone_id   = "ru-central1-c"
      subnet_id = yandex_vpc_subnet.public-subnet.id
    }
  }

  listener {
    name = "listener"
    endpoint {
      address {
        external_ipv4_address {
        }
      }
      ports = [80]
    }
    http {
      handler {
        http_router_id = yandex_alb_http_router.router.id
      }
    }
  }
}

#security groups

#load balancer

resource "yandex_vpc_security_group" "load-balancer-sg" {
  name       = "load-balancer-sg"
  network_id = yandex_vpc_network.vpc.id

  ingress {
    protocol          = "ANY"
    v4_cidr_blocks    = ["0.0.0.0/0"]
    predefined_target = "loadbalancer_healthchecks"
  }

  ingress {
    protocol       = "TCP"
    v4_cidr_blocks = ["0.0.0.0/0"]
    port           = 80
  }

  ingress {
    protocol       = "ICMP"
    v4_cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    protocol       = "ANY"
    v4_cidr_blocks = ["0.0.0.0/0"]
  }
}

#websites

resource "yandex_vpc_security_group" "websites-sg" {
  name       = "websites-sg"
  network_id = yandex_vpc_network.vpc.id

  ingress {
    protocol       = "TCP"
    v4_cidr_blocks = ["192.168.40.0/24"]
    port           = 10050
  }

  ingress {
    protocol       = "TCP"
    v4_cidr_blocks = ["192.168.50.0/24"]
    port           = 22
    predefined_target = "yandex_vpc_security_group.bastion-sg.id"
  }

  ingress {
    protocol       = "TCP"
    v4_cidr_blocks = ["0.0.0.0/0"]
    port           = 80
  }

  ingress {
    protocol       = "ICMP"
    v4_cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    protocol       = "ANY"
    v4_cidr_blocks = ["0.0.0.0/0"]
  }
}

#bastion

resource "yandex_vpc_security_group" "bastion-sg" {
  name       = "bastion-sg"
  network_id = yandex_vpc_network.vpc.id

  ingress {
    protocol       = "TCP"
    v4_cidr_blocks = ["192.168.40.0/24"]
    port           = 10050
  }

  ingress {
    protocol       = "TCP"
    v4_cidr_blocks = ["0.0.0.0/0"]
    port           = 22
  }

  ingress {
    protocol       = "ICMP"
    v4_cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    protocol       = "ANY"
    v4_cidr_blocks = ["0.0.0.0/0"]
  }
}

#elasticsearch

resource "yandex_vpc_security_group" "elasticsearch-sg" {
  name       = "elasticsearch-sg"
  network_id = yandex_vpc_network.vpc.id

  ingress {
    protocol       = "TCP"
    v4_cidr_blocks = ["192.168.40.0/24"]
    port           = 10050
  }

  ingress {
    protocol       = "TCP"
    v4_cidr_blocks = ["192.168.50.0/24"]
    port           = 22
    predefined_target = "yandex_vpc_security_group.bastion-sg.id"
  }

  ingress {
    protocol       = "TCP"
    v4_cidr_blocks = ["192.168.10.0/24", "192.168.20.0/24", "192.168.30.0/24", "192.168.40.0/24"]
    port           = 9200
  }

  ingress {
    protocol       = "ICMP"
    v4_cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    protocol       = "ANY"
    v4_cidr_blocks = ["0.0.0.0/0"]
    
  }
}

#kibana

resource "yandex_vpc_security_group" "kibana-sg" {
  name       = "kibana-sg"
  network_id = yandex_vpc_network.vpc.id

  ingress {
    protocol       = "TCP"
    v4_cidr_blocks = ["192.168.50.0/24"]
    port           = 22
    predefined_target = "yandex_vpc_security_group.bastion-sg.id"
  }

  ingress {
    protocol       = "TCP"
    v4_cidr_blocks = ["0.0.0.0/0"]
    port           = 5601
  }

  ingress {
    protocol       = "TCP"
    v4_cidr_blocks = ["192.168.40.0/24"]
    port           = 10050
  }

  ingress {
    protocol       = "ICMP"
    v4_cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    protocol       = "ANY"
    v4_cidr_blocks = ["0.0.0.0/0"]
        
  }
}

#zabbix

resource "yandex_vpc_security_group" "zabbix-sg" {
  name       = "zabbix-sg"
  network_id = yandex_vpc_network.vpc.id

  ingress {
    protocol       = "TCP"
    v4_cidr_blocks = ["0.0.0.0/0"]
    port           = 80
  }

  ingress {
    protocol       = "TCP"
    v4_cidr_blocks = ["192.168.50.0/24"]
    port           = 22
    predefined_target = "yandex_vpc_security_group.bastion-sg.id"
  }

  ingress {
    protocol       = "ANY"
    v4_cidr_blocks = ["192.168.10.0/24", "192.168.20.0/24", "192.168.30.0/24", "192.168.40.0/24", "192.168.50.0/24"]
    from_port      = 10050
    to_port        = 10051
  }
  
  ingress {
    protocol       = "ICMP"
    v4_cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    protocol       = "ANY"
    v4_cidr_blocks = ["0.0.0.0/0"]
    from_port      = 0
    to_port        = 65535
  }
}