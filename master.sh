#!/bin/bash

#COLOR
    cy=$(tput setaf 118)
    rst=$(tput sgr0)

function sleep_and_clear {
    sleep 1.5
    clear
}
clear
echo -e "${cy}ADDING DOCKER DAEMON CONFIGS TO USE SYSTEMD AS CGROUP DRIVER${rst}"
echo -e
cat <<EOF | sudo tee /etc/docker/daemon.json
{
  "exec-opts": ["native.cgroupdriver=systemd"],
  "log-driver": "json-file",
  "log-opts": {
    "max-size": "100m"
  },
  "storage-driver": "overlay2"
}
EOF
sleep_and_clear

echo "${cy}RESETING AND ENABLING DOCKER${rst}"
    echo
    sudo systemctl enable docker >/dev/null
    sudo systemctl daemon-reload >/dev/null
    sudo systemctl restart docker >/dev/null
    sleep_and_clear

echo "${cy}RESETING KUBEADM${rst}"
    echo
    sudo kubeadm reset
    sleep_and_clear

echo "${cy}CHECKING FOR OLD KUBE FILES AND REMOVING THEM${rst}"
    echo
    sudo rm -dR /etc/cni/net.d
    sudo rm -f $HOME/.kube/config
    sudo rm -f /etc/kubernetes/manfests/*
    sleep_and_clear

echo "${cy}UPDATING SYSTEM${rst}"
    echo
    sudo sysctl --system
    sudo apt-get update -y > /dev/null
    sleep_and_clear

echo "${cy}INSTALLING CURL, CA-CERTS, APT-TRANSPORT-HTTPS${rst}"
    echo
    sudo apt-get install -y apt-transport-https ca-certificates curl > /dev/null
    sleep_and_clear

echo "${cy}DOWNLOADING GPG KEYRING${rst}"
    echo
    sudo curl -fsSLo /usr/share/keyrings/kubernetes-archive-keyring.gpg \
    https://packages.cloud.google.com/apt/doc/apt-key.gpg
    sleep_and_clear

echo "deb [signed-by=/usr/share/keyrings/kubernetes-archive-keyring.gpg] \
https://apt.kubernetes.io/ kubernetes-xenial main" | sudo tee /etc/apt/sources.list.d/kubernetes.list
    echo
    sudo apt-get update -y >/dev/null
    sudo apt-get install -y kubelet kubeadm kubectl >/dev/null
    sudo apt-mark hold kubelet kubeadm kubectl >/dev/null
    sleep_and_clear

echo "${cy}TURNING OFF SWAP${rst}"
    echo
    sudo swapoff -a
    sudo sed -i '/ swap / s/^\(.*\)$/#\1/g' /etc/fstab
    sleep_and_clear

echo "${cy}EXECUTING JOIN COMMAND${rst}"
    echo
    sudo kubeadm init --apiserver-advertise-address=172.31.34.60 \
    --apiserver-cert-extra-sans=172.31.34.60  \
    --pod-network-cidr=172.31.0.0/16
    sleep_and_clear

echo "${cy}CREATING KUBE DIRECTORY AND SETTING USER PERMISSIONS${rst}"
    echo 
    mkdir -p $HOME/.kube
    sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
    sudo chown $(id -u):$(id -g) $HOME/.kube/config
    sleep_and_clear

echo "PRINTING CLUSTER, NODE, AND KUBE-SYSTEM INFO"
    echo
    kubectl cluster-info
    kubectl get nodes
    kubectl get po -n kube-system
    sleep 5
    clear

echo "${cy}REMOVING AND TAINT NODES${rst}"
    echo
    kubectl taint nodes --all node-role.kubernetes.io/master-
    sleep_and_clear
    kubectl create -f https://docs.projectcalico.org/manifests/tigera-operator.yaml
    kubectl create -f https://docs.projectcalico.org/manifests/custom-resources.yaml
    curl -o kubectl-calico -O -L  "https://github.com/projectcalico/calicoctl/releases/download/v3.21.0/calicoctl" 
    chmod +x kubectl-calico

echo "${cy}USE THIS TO JOIN THE WORKER NODE TO THE MASTER NODE${rst}"
    echo
    kubeadm token create --print-join-command
    echo
