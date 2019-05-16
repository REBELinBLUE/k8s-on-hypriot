#!/bin/sh

e_header() {
    export CLI_MAGENTA=$(tput -Txterm-256color setaf 5)
    export CLI_BOLD=$(tput -Txterm-256color bold)
    export CLI_RESET=$(tput -Txterm-256color sgr0)

    printf "\n${CLI_BOLD}${CLI_MAGENTA}==========  %s  ==========${CLI_RESET}\n" "$@"
}

e_header "Adding Node Labels"
kubectl label node master node-role.kubernetes.io/edge=""
kubectl label node node-1 blinktShow=true
kubectl label node node-2 blinktShow=true
kubectl label node node-3 blinktShow=true
kubectl label node master blinktShow=true
kubectl label node master blinktImage=nodes
kubectl label node node-1 blinktImage=pods
kubectl label node node-2 blinktImage=pods
kubectl label node node-3 blinktImage=pods

kubectl -n infra apply -f dashboards-auth.yaml

e_header "Installing Flannel"
kubectl -n infra apply -f 1-Flannel/

e_header "Installing MetalLB"
kubectl -n infra apply -f 2-MetalLB/

e_header "Installing Traefik"
kubectl -n infra apply -f 3-Traefik/

e_header "Installing Kubernetes Dashboard"
kubectl -n kube-system apply -f 4-Dashboard/

e_header "Installing Metrics Server"
kubectl -n kube-system apply -f 5-Metrics-server/

e_header "Installing NFS Storage"
kubectl -n infra apply -f 6-NFS_Storage/
kubectl -n infra patch storageclass nfs-hdd -p '{"metadata": {"annotations":{"storageclass.kubernetes.io/is-default-class":"true"}}}'
kubectl -n infra patch deployment nfs-client-provisioner -n infra --patch '{"spec": {"template": {"spec": {"nodeSelector": {"beta.kubernetes.io/arch": "arm"}}}}}'

e_header "Installing Helm"
kubectl -n kube-system apply -f 7-Helm/rbac-config.yaml
helm init --service-account tiller --tiller-image jessestuart/tiller
kubectl -n kube-system patch deployment tiller-deploy --patch '{"spec": {"template": {"spec": {"nodeSelector": {"beta.kubernetes.io/arch": "arm"}}}}}'

e_header "Installing Loki & Promtail"
kubectl -n infra apply -f 8-Logging/

e_header "Installing Node Exporter"
kubectl -n kube-system apply -f 9-Monitoring/node-exporter.yaml

e_header "Installing Prometheus & Alert Manager"
kubectl -n infra apply -f 9-Monitoring/prometheus.yaml
kubectl -n infra apply -f 9-Monitoring/alertmanager.yaml

e_header "Installing Grafana"
kubectl -n infra apply -f 9-Monitoring/grafana.yaml

e_header "Installing ARM exporter"
kubectl -n infra apply -f 9-Monitoring/arm-exporter.yaml

e_header "Installing Kube-state Metrics"
kubectl -n infra apply -f 9-Monitoring/kube-state-metrics.yaml

e_header "Installing Blinkt"
kubectl -n infra apply -f 10-Blinkt/

e_header "Installing Forecastle"
kubectl -n infra apply -f 11-Others/forecastle.yaml

e_header "Installing Reloader"
kubectl -n infra apply -f 11-Others/reloader.yaml

e_header "Installing Kubeview"
kubectl -n infra apply -f 11-Others/kubeview.yaml

#e_header "Installing Kubernetes Descheduler"
#kubectl -n kube-system apply -f 11-Others/descheduler.yaml

e_header "Getting Dashboard Token"
kubectl -n kube-system describe secret $(kubectl -n kube-system get secret | grep kubernetes-dashboard | awk '{print $1}')
