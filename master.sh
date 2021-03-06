#!/bin/bash

#COLOR
    cy=$(tput setaf 118)
    rst=$(tput sgr0)

function sleep_and_clear {
    sleep 1.5
    clear
}
clear
echo "${cy}ADDING DOCKER DAEMON CONFIGS TO USE SYSTEMD AS CGROUP DRIVER${rst}"
echo
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

echo "${cy}EXECUTING INIT COMMAND${rst}"
    echo
echo "${cy}BUT FIRST, I NEED SOME INFORMATION... ${rst}"
    echo
read -p "${cy}ENTER API SERVER ADVERTISE IP ADDRESS: ${rst}" IPADDRESS
read -p "${cy}ENTER POD NETWORK CIDR EX 192.168.0.0/16: ${rst}" IPCIDR
echo "${cy}COOL, THANKS... ${rst}"
    echo
    sudo kubeadm init --apiserver-advertise-address=${IPADDRESS} \
    --apiserver-cert-extra-sans=${IPADDRESS}  \
    --pod-network-cidr=${IPCIDR} >/dev/null
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

echo "${cy}INSTALLING AND APPLYING CALICO CNI..${rst}"
    echo
    kubectl apply -f https://docs.projectcalico.org/manifests/calico.yaml >/dev/null
    sleep_and_clear

echo "${cy}INSTALLING AND APPLYING CALICO CNI..${rst}"
    echo
    kubectl apply -f https://projectcontour.io/examples/kuard.yaml
    kubectl get po,svc,ing -l app=kuard
    sleep_and_clear

echo "${cy}USE THIS TO JOIN THE WORKER NODE TO THE MASTER NODE${rst}"
    echo
    kubeadm token create --print-join-command
    echo
