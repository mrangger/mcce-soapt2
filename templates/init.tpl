#!/bin/bash

# Install dependencies docker, docker-compose
sudo yum update -y
sudo amazon-linux-extras install docker -y
sudo service docker start
sudo systemctl enable docker
sudo usermod -a -G docker ec2-user
sudo curl -L https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m) -o /usr/bin/docker-compose
sudo chmod +x /usr/bin/docker-compose

# Set Domainname
curl "https://infomaniak.com/nic/update?hostname=${domain_name}&username=${dns_username}&password=${dns_password}"
curl "https://infomaniak.com/nic/update?hostname=nginx.${domain_name}&username=${dns_username}&password=${dns_password}"
curl "https://infomaniak.com/nic/update?hostname=portainer.${domain_name}&username=${dns_username}&password=${dns_password}"
curl "https://infomaniak.com/nic/update?hostname=traefik.${domain_name}&username=${dns_username}&password=${dns_password}"

project_dir="/docker"

mkdir -p $${project_dir}
touch $${project_dir}/acme.json
chmod 0600 $${project_dir}/acme.json


# Create docker-compose config
cat << "EOF" > $${project_dir}/docker-compose.yaml

version: "3.3"

services:
  traefik:
    container_name: traefik
    image: "traefik"
    command:
      - --entrypoints.web.address=:80
      - --entrypoints.web.http.redirections.entryPoint.to=websecure
      - --entrypoints.web.http.redirections.entryPoint.scheme=https
      - --entrypoints.websecure.address=:443
      - --entrypoints.websecure.http.tls=true
      - --entrypoints.websecure.http.tls.certResolver=leresolver
      - --entrypoints.websecure.http.tls.domains[0].main=${domain_name}
      - --entrypoints.websecure.http.tls.domains[0].sans=traefik.${domain_name},portainer.${domain_name},nginx.${domain_name}
      - --api.dashboard=true
      - --providers.docker
#      - --log.level=DEBUG
      - --certificatesresolvers.leresolver.acme.email=${email_address}
      - --certificatesresolvers.leresolver.acme.storage=./acme.json
#      - --certificatesresolvers.leresolver.acme.caserver=https://acme-staging-v02.api.letsencrypt.org/directory
      - --certificatesresolvers.leresolver.acme.dnschallenge=true
      - --certificatesresolvers.leresolver.acme.dnschallenge.provider=infomaniak
      - --certificatesresolvers.leresolver.acme.dnschallenge.delaybeforecheck=5
      - --certificatesresolvers.leresolver.acme.dnschallenge.resolvers=ns41.infomaniak.com:53,ns42.infomaniak.com:53


    environment:
      - "INFOMANIAK_ACCESS_TOKEN=${dns_token}"
    ports:
      - "80:80"
      - "443:443"
    volumes:
      - "/etc/localtime:/etc/localtime:ro"
      - "/var/run/docker.sock:/var/run/docker.sock:ro"
      - "./acme.json:/acme.json"
    labels:
      - "traefik.enable=true"
      - "traefik.http.routers.dashboard.entrypoints=websecure"
      - "traefik.http.routers.dashboard.rule=Host(`traefik.${domain_name}`)"
      - "traefik.http.routers.dashboard.service=api@internal"
      - "traefik.http.routers.dashboard.middlewares=auth"
      - "traefik.http.middlewares.auth.basicauth.users=admin:${admin_password}"

  nginx:
    image: nginx
    restart: always
    labels:
      - "traefik.enable=true"
      - "traefik.http.routers.nginx.rule=Host(`nginx.${domain_name}`)"
      - "traefik.http.routers.nginx.entrypoints=websecure"
      - "traefik.http.services.nginx.loadbalancer.server.port=80"
      
      
  portainer:
    image: portainer/portainer-ce
    command: "-H unix:///var/run/docker.sock --admin-password=${admin_password}"
    restart: always
    volumes:
      - /var/run/docker.sock:/var/run/docker.sock
      - portainer_data:/data
    labels:
      - "traefik.enable=true"
      - "traefik.http.routers.portainer.rule=Host(`portainer.${domain_name}`)"
      - "traefik.http.routers.portainer.entrypoints=websecure"
      - "traefik.http.services.portainer.loadbalancer.server.port=9000"

volumes:
  portainer_data:
  
EOF

# Create traefic letsencrypt config
cat << "EOF" > $${project_dir}/acme.json
{
  "leresolver": {
    "Account": {
      "Email": "${email_address}",
      "Registration": {
        "body": {
          "status": "valid",
          "contact": [
            "mailto:${email_address}"
          ]
        },
        "uri": "https://acme-v02.api.letsencrypt.org/acme/acct/374543210"
      },
      "PrivateKey": "${dns_pk}",
      "KeyType": "4096"
    },
    "Certificates": null
  }
}
EOF

chmod 0600 $${project_dir}/acme.json

cd $${project_dir}
docker-compose up
