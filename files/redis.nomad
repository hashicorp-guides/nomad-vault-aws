job "redis" {
  datacenters = ["dc1"]
  type = "service"

  update {
    stagger = "10s"
    max_parallel = 1
  }

  group "redis" {
    count = 1

    restart {
      attempts = 10
      interval = "5m"
      delay = "25s"
      mode = "delay"
    }

    ephemeral_disk {
      sticky = true
      migrate = true
      size = 300
    }

    task "redis" {
      driver = "docker"
      config {
        image = "redis:latest"
    command = "redis-server"
    args = ["--appendonly yes", "--dir /alloc/data"]
        port_map {
          db = 6379
        }
      }

      resources {
        cpu    = 500 # 500 MHz
        memory = 256 # 256MB
        network {
          mbits = 10
          port "db" {}
        }
      }

      service {
        name = "global-redis-check"
        tags = ["global", "cache"]
        port = "db"
        check {
          name     = "alive"
          type     = "tcp"
          interval = "10s"
          timeout  = "2s"
        }
      }

      vault {
        policies = ["redis"]
      }
    }
  }
}
