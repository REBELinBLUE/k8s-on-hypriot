#!/bin/sh

export HELM_VERSION=v2.14.2
export HELM_INSTALL_DIR=/usr/local/bin
wget https://kubernetes-helm.storage.googleapis.com/helm-$HELM_VERSION-linux-arm.tar.gz
tar xvzf helm-$HELM_VERSION-linux-arm.tar.gz
sudo mv linux-arm/helm $HELM_INSTALL_DIR/helm
rm -rf linux-arm helm-$HELM_VERSION-linux-arm.tar.gz

# curl https://raw.githubusercontent.com/helm/helm/master/scripts/get | bash
kubectl apply -f rbac-config.yaml
helm init --service-account tiller --tiller-image jessestuart/tiller
kubectl patch deployment tiller-deploy -n kube-system --patch '{"spec": {"template": {"spec": {"nodeSelector": {"beta.kubernetes.io/arch": "arm"}}}}}'
helm list
