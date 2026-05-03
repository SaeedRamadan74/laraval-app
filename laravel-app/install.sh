#!/bin/bash
set -e

echo "================ CLEAN SYSTEM ================="
sudo rm -f /etc/apt/sources.list.d/jenkins.list
sudo rm -rf /var/lib/apt/lists/*

echo "================ UPDATE SYSTEM ================="
sudo apt update -y
sudo apt upgrade -y

# ================= JAVA =================
echo "================ INSTALL JAVA ================="
sudo apt install -y fontconfig openjdk-21-jre
java -version

# ================= BASE =================
echo "================ INSTALL BASE PACKAGES ================="
sudo apt install -y curl wget gnupg lsb-release ca-certificates software-properties-common unzip zip

# ================= JENKINS =================
echo "================ INSTALL JENKINS ================="

sudo mkdir -p /etc/apt/keyrings

# Official Jenkins key (latest)
wget -O /etc/apt/keyrings/jenkins-keyring.asc \
  https://pkg.jenkins.io/debian-stable/jenkins.io-2026.key

echo "deb [signed-by=/etc/apt/keyrings/jenkins-keyring.asc] \
https://pkg.jenkins.io/debian-stable binary/" | \
sudo tee /etc/apt/sources.list.d/jenkins.list > /dev/null

sudo apt update -y
sudo apt install -y jenkins

sudo systemctl daemon-reexec
sudo systemctl daemon-reload
sudo systemctl enable jenkins
sudo systemctl start jenkins

# ================= GIT =================
echo "================ INSTALL GIT ================="
sudo apt install -y git

# ================= DOCKER =================
echo "================ INSTALL DOCKER ================="

sudo mkdir -p /etc/apt/keyrings

curl -fsSL https://download.docker.com/linux/ubuntu/gpg | \
sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg

UBUNTU_CODENAME=$(lsb_release -cs)
if [[ "$UBUNTU_CODENAME" != "jammy" && "$UBUNTU_CODENAME" != "noble" ]]; then
  UBUNTU_CODENAME="noble"
fi

echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] \
https://download.docker.com/linux/ubuntu $UBUNTU_CODENAME stable" | \
sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

sudo apt update -y
sudo apt install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

sudo systemctl enable docker
sudo systemctl start docker

# ================= DOCKER PERMISSIONS =================
echo "================ CONFIGURE DOCKER ================="

if ! getent group docker > /dev/null; then
    sudo groupadd docker
fi

sudo usermod -aG docker ubuntu

# ================= ANSIBLE =================
echo "================ INSTALL ANSIBLE ================="
sudo apt install -y ansible-core

# ================= KUBERNETES TOOLS =================
echo "================ INSTALL KUBECTL ================="
curl -LO "https://dl.k8s.io/release/$(curl -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl

echo "================ INSTALL MINIKUBE ================="
curl -LO https://storage.googleapis.com/minikube/releases/latest/minikube-linux-amd64
sudo install minikube-linux-amd64 /usr/local/bin/minikube

echo "================ INSTALL EKSCTL ================="
curl --silent --location \
"https://github.com/weaveworks/eksctl/releases/latest/download/eksctl_$(uname -s)_amd64.tar.gz" \
| tar xz -C /tmp
sudo mv /tmp/eksctl /usr/local/bin

echo "================ INSTALL K9S ================="
wget https://github.com/derailed/k9s/releases/latest/download/k9s_Linux_amd64.tar.gz
tar -xzf k9s_Linux_amd64.tar.gz
sudo install -m 755 k9s /usr/local/bin/k9s

# ================= AWS CLI =================
echo "================ INSTALL AWS CLI ================="
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
sudo ./aws/install

# ================= KOMPOSE =================
echo "================ INSTALL KOMPOSE ================="
wget https://github.com/kubernetes/kompose/releases/latest/download/kompose-linux-amd64 -O kompose
chmod +x kompose
sudo mv kompose /usr/local/bin/

# ================= FINAL =================
echo "================ JENKINS PASSWORD ================="
sudo cat /var/lib/jenkins/secrets/initialAdminPassword

echo "================ DONE ================="
echo "Jenkins: http://<EC2-IP>:8080"