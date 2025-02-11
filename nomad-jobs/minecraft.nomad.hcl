# See https://github.com/itzg/docker-minecraft-server/tree/master/examples

job "minecraft-servers" {
  datacenters = ["*"]
  type        = "service"

  ui {
    description = <<-HEREDOC
    Minecraft (Java Edition)
    HEREDOC

    link {
      label = "Minecraft Servers"
    }

  }

  group "world-1" {
    count = 1

    network {
      mode = "bridge"
      
      port "tcp" {
        to = 25565
      }
    }

    service {
      provider = "nomad"
      name     = "minecraft"
      port     = "tcp"
      
      tags = var.tags
    }

    volume "mc-data" {
      type      = "host"
      read_only = false
      source    = var.volume_source
    }

    restart {
      attempts = 1
      interval = "15m"
      delay    = "30s"
      mode     = "fail"
    }

    task "minecraft" {
      driver = "podman"
      leader = true

      resources {
        cpu        = 2000
        memory     = 8192
      }

      volume_mount {
        volume      = "mc-data"
        destination = "/data"
        read_only   = false
      }

      env = {
        EULA    = "TRUE"
        VERSION = "LATEST"
        TYPE    = "VANILLA"
        OPS     = "Example" # See https://docker-minecraft-server.readthedocs.io/en/latest/configuration/server-properties/#opadministrator-players

        # See https://docker-minecraft-server.readthedocs.io/en/latest/configuration/server-properties/
        #OVERRIDE_SERVER_PROPERTIES = "false"
        #DUMP_SERVER_PROPERTIES     = true
      }

      config {
        image = var.image
        ports = ["tcp"]
      }
    }
  }
}

////////////////////////
// Variables
////////////////////////

variable "image" {
  type    = string
  default = "docker.io/itzg/minecraft-server:latest"
}

variable "volume_source" {
  type    = string
  default = "minecraft-data"
}

variable "tags" {
  type = list(string)
  default = [
    "traefik.enable=true",
    "traefik.tcp.routers.mc1.entrypoints=minecraft",
    "traefik.tcp.routers.mc1.rule=HostSNI(`*`)",
  ]
}