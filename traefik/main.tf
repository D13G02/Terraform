resource "docker_image" "traefik" {
  name = "traefik:v2.6"
}

resource "docker_network" "external_network" {
  name   = "proxy"
  driver = "bridge"
  internal = false
}

resource "docker_container" "traefik" {
  name = "traefik"
  image = docker_image.traefik.name
  restart = "unless-stopped"
  
  # Networks
  networks_advanced {
    name = docker_network.external_network.name
    aliases = ["proxy"]
  }
  
  # HTTP Ports
  ports {
    internal = "80"
    external = "80"
    ip = "0.0.0.0"
  }

  # HTTPS Ports
  ports {
    internal = "443"
    external = "443"
    ip = "0.0.0.0"
  }

  # Volumes
  volumes {
    host_path = "/etc/localtime"
    container_path = "/etc/localtime"
    read_only = "true"
  }

  volumes { 
    host_path = "/var/run/docker.sock"
    container_path = "/var/run/docker.sock"
    read_only = "true"
  }

  volumes { 
    host_path = "/data/traefik.yaml"
    container_path = "/traefik.yaml"
    read_only = "true"
  }

  # Labels
  labels {
    label = "traefik.enable"
    value = true
  }

  labels {
    label = "traefik.http.routers.traefik.entrypoints"
    value = "http"
  }

  labels {
    label = "traefik.http.routers.traefik.rule"
    value = "Host(`traefik.example.com`)"
  }

  labels {
    label = "traefik.http.middlewares.traefik-https-redirect.redirectscheme.scheme"
    value = "https"
  }

  labels {
    label = "traefik.http.routers.traefik.middlewares"
    value = "traefik-https-redirect"
  }

  labels {
    label = "traefik.http.routers.traefik-secure.entrypoints"
    value = "https"
  }

  labels {
    label = "traefik.http.routers.traefik-secure.rule"
    value = "Host(`traefik.example.com`)"
  }
 
  labels {
    label = "traefik.http.routers.traefik-secure.tls"
    value = true
  }

  labels {
    label = "traefik.http.routers.traefik-secure.tls.certresolver"
    value = "http"
  }

  labels {
    label = "traefik.http.routers.traefik-secure.service"
    value = "api@internal"
  }

}
