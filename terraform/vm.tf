#website1

resource "yandex_compute_instance" "website1" {
  name     = "website1"
  hostname = "website1"
  zone     = "ru-central1-a"

  resources {
    cores  = 2
    memory = 2
    core_fraction = 20
  }

  boot_disk {
    initialize_params {
      image_id = "fd8vljd295nqdaoogf3g"
      size = 10
    }
  }

  network_interface {
    subnet_id          = yandex_vpc_subnet.private-subnet-1.id
    security_group_ids = [yandex_vpc_security_group.websites-sg.id]
    ip_address         = "192.168.10.3"
  }

  metadata = {		
    user-data = "${file("./meta1.yaml")}"			
  }

scheduling_policy {
    preemptible = true
  }
}

#website2

resource "yandex_compute_instance" "website2" {
  name     = "website2"
  hostname = "website2"
  zone     = "ru-central1-b"

  resources {
    cores  = 2
    memory = 2
    core_fraction = 20
  }

  boot_disk {
    initialize_params {
      image_id = "fd8vljd295nqdaoogf3g"
      size = 10
    }
  }

  network_interface {
    subnet_id          = yandex_vpc_subnet.private-subnet-2.id
    security_group_ids = [yandex_vpc_security_group.websites-sg.id]
    ip_address         = "192.168.20.3"
  }

  metadata = {		
    user-data = "${file("./meta2.yaml")}"			
  }

scheduling_policy {
    preemptible = true
  }
}

#zabbix 

resource "yandex_compute_instance" "zabbix" {
  name     = "zabbix"
  hostname = "zabbix"
  zone     = "ru-central1-c"

  resources {
    cores  = 2
    memory = 2
    core_fraction = 20
  }

  boot_disk {
    initialize_params {
      image_id = "fd8vljd295nqdaoogf3g"
      size     = 10
    }
  }

  network_interface {
    subnet_id          = yandex_vpc_subnet.public-subnet.id
    security_group_ids = [yandex_vpc_security_group.zabbix-sg.id]
    ip_address         = "192.168.40.3"
    nat                = true
  }

  metadata = {
    user-data = "${file("./meta.yaml")}"
  }

scheduling_policy {
    preemptible = true
  }
}

#elasticsearch

resource "yandex_compute_instance" "elasticsearch" {
  name     = "elasticsearch"
  hostname = "elasticsearch"
  zone     = "ru-central1-c"
  allow_stopping_for_update = true

  resources {
    cores  = 2
    memory = 4
    core_fraction = 20
  }

  boot_disk {
    initialize_params {
      image_id = "fd8vljd295nqdaoogf3g"
      size     = 10
    }
  }

  network_interface {
    subnet_id          = yandex_vpc_subnet.private-subnet-3.id
    security_group_ids = [yandex_vpc_security_group.elasticsearch-sg.id]
    ip_address         = "192.168.30.3"
  }

  metadata = {
    user-data = "${file("./meta.yaml")}"
  }

scheduling_policy {
    preemptible = true
  }
}

#kibana

resource "yandex_compute_instance" "kibana" {
  name     = "kibana"
  hostname = "kibana"
  zone     = "ru-central1-c"
  allow_stopping_for_update = true

  resources {
    cores  = 2
    memory = 4
    core_fraction = 20
  }

  boot_disk {
    initialize_params {
      image_id = "fd8vljd295nqdaoogf3g"
      size = 10
    }
  }

  network_interface {
    subnet_id          = yandex_vpc_subnet.public-subnet.id
    security_group_ids = [yandex_vpc_security_group.kibana-sg.id]
    ip_address         = "192.168.40.4"
    nat                = true
  }

  metadata = {
    user-data = "${file("./meta.yaml")}"
  }

scheduling_policy {
    preemptible = true
  }
}

#bastion

resource "yandex_compute_instance" "bastion" {
  name     = "bastion"
  hostname = "bastion"
  zone     = "ru-central1-c"

  resources {
    cores  = 2
    memory = 2
    core_fraction = 20
  }

  boot_disk {
    initialize_params {
      image_id = "fd8vljd295nqdaoogf3g"		
      size     = 10 
    }
  }

  network_interface {
    subnet_id          = yandex_vpc_subnet.public-bastion-subnet.id
    security_group_ids = [yandex_vpc_security_group.bastion-sg.id]
    ip_address         = "192.168.50.3"
    nat                = true
  }

  metadata = {
    user-data = "${file("./meta.yaml")}"
  }

scheduling_policy {
    preemptible = true
  }
}