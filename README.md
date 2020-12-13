# damp-lab-1081
GitOps repository for the damp-lab-1081 k8s cluster running on Hypriot/Raspberry Pi 4/CloverPi

## Bootstrapping the cluster

    kubectl apply -f kube-system/sealed-secrets.yaml

## Operations and maintenance

### Update Sealed Secrets

    export VERSION=v0.…
    curl -sLo kube-system/sealed-secrets.yaml "https://github.com/bitnami-labs/sealed-secrets/releases/download/${VERSION}/controller.yaml"
