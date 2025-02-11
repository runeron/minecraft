# See https://github.com/itzg/docker-minecraft-server/tree/master/examples

job "traefik-proxy" {
  datacenters = ["*"]
  type        = "service"

  ui {
    description = "Traefik Proxy"
  }

  group "traefik" {
    count = 1

    network {
      mode = "bridge"
      
      port "http" {
        static = 80
        to     = 80
      }
      
      port "https" {
        static = 443
        to     = 443
      }
      
      port "traefik" {
        static = 8080
        to     = 8080
      }

      port "minecraft" {
        static = 5050
        to     = 5050
      }
    }

    volume "certs" {
      type      = "host"
      read_only = false
      source    = var.volume_source
    }

    restart {
      attempts = 3
      interval = "15m"
      delay    = "30s"
      mode     = "fail"
    }

    task "traefik" {
      driver = "podman"
      leader = true

      identity {
        env = true
      }

      resources {
        cpu    = 250
        memory = 512
      }

      volume_mount {
        volume      = "certs"
        destination = "/certs"
        read_only   = false
      }

      config {
        image = var.image
        ports = ["http", "https", "minecraft", "traefik"]
        
        args = [
          "--api.dashboard=true",
          "--api.insecure=true",
          "--entrypoints.http.address=:${NOMAD_PORT_http}",
          "--entrypoints.https.address=:${NOMAD_PORT_https}",
          "--entrypoints.minecraft.address=:${NOMAD_PORT_minecraft}",
          "--entrypoints.traefik.address=:${NOMAD_PORT_traefik}",
          "--providers.nomad=true",
          "--providers.nomad.endpoint.address=unix:///${NOMAD_SECRETS_DIR}/api.sock",
          "--providers.nomad.prefix=traefik",
          "--providers.nomad.exposedByDefault=false",
        ]
      }
    }
  }
}

////////////////////////
// Variables
////////////////////////

variable "image" {
  type    = string
  default = "docker.io/traefik:latest"
}

variable "volume_source" {
  type    = string
  default = "traefik-certs"
}