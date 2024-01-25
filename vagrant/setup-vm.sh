!/bin/bash

# Check if the user is running the script as root
if [ "$EUID" -ne 0 ]; then
  echo "Please run this script as root or using sudo."
  exit 1
fi

# Install Docker
echo "----------------------Installing Docker----------------------"
curl -fsSL https://get.docker.com | sh
systemctl enable docker
systemctl start docker

# Add the current user to the Docker group
echo "Adding current user to the Docker group..."
#groupadd docker
gpasswd -a $USER docker
newgrp docker

# Install Docker Compose
echo "----------------------Installing Docker Compose----------------------"
# Docker Compose
compose_release() {
  curl --silent "https://api.github.com/repos/docker/compose/releases/latest" |
    grep -Po '"tag_name": "\K.*?(?=")'
}

if ! [ -x "$(command -v docker-compose)" ]; then
  curl -L https://github.com/docker/compose/releases/download/$(compose_release)/docker-compose-$(uname -s)-$(uname -m) \
    -o /usr/local/bin/docker-compose && chmod +x /usr/local/bin/docker-compose
fi

# Run a test Docker command
echo "----------------------Running 'docker run hello-world' to test Docker installation----------------------"
docker run hello-world

# Optional: Check the versions
docker --version
docker compose --version
sleep 5

echo "----------------------Create nginx container runtime----------------------"
docker run --name nginx -d -p 80:80 nginx
systemctl enable docker.service
cat <<EOL >/etc/systemd/system/nginx_docker_container.service
[Unit]
Wants=docker.service
After=docker.service

[Service]
RemainAfterExit=yes
ExecStart=/usr/bin/docker start nginx
ExecStop=/usr/bin/docker stop nginx

[Install]
WantedBy=multi-user.target
EOL
systemctl start nginx_docker_container
systemctl enable nginx_docker_container
