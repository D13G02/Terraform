resource "docker_image" "portainer" {
  name = "portainer/portainer:latest"
}

resource "docker_container" "portainer" {
  name = "portainer"
  image = docker_image.portainer.name
  restart = "unless-stopped"
  
  # Networks
  networks_advanced {
    name = "proxy"
    aliases = ["proxy"]
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
    host_path = "/data"
    container_path = "/data"
  }

  # Labels
  labels {
    label = "traefik.enable"
    value = true
  }

  labels {
    label = "traefik.http.routers.portainer.entrypoints"
    value = "http"
  }

  labels {
    label = "traefik.http.routers.portainer.rule"
    value = "Host(`portainer.example.com`)"
  }

  labels {
    label = "traefik.http.middlewares.portainer-https-redirect.redirectscheme.scheme"
    value = "https"
  }

  labels {
    label = "traefik.http.routers.portainer.middlewares"
    value = "portainer-https-redirect"
  }

  labels {
    label = "traefik.http.routers.portainer-secure.entrypoints"
    value = "https"
  }

  labels {
    label = "traefik.http.routers.portainer-secure.rule"
    value = "Host(`portainer.example.com`)"
  }
 
  labels {
    label = "traefik.http.routers.portainer-secure.tls"
    value = true
  }

  labels {
    label = "traefik.http.routers.portainer-secure.tls.certresolver"
    value = "http"
  }

  labels {
    label = "traefik.http.routers.portainer-secure.service"
    value = "portainer"
  }

  labels {
    label = "traefik.http.services.portainer.loadbalancer.server.port"
    value = "9000"
  }

  labels {
    label = "traefik.docker.network"
    value = "proxy"
  }

}
