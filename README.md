# damp-lab-1081
GitOps repository for the damp-lab-1081 k8s cluster running on Hypriot/Raspberry Pi 4/CloverPi

## Bootstrapping the cluster

1. Apply the private key for Sealed Secrets

   gpg --decrypt sealed-secrets-key.asc | kubectl create -f -

2. Install Sealed Secrets

    kubectl apply -f kube-system/sealed-secrets.yaml

3. Install ArgoCD

    kubectl create ns argocd
    kubectl apply -n argocd -f argocd/argocd.yaml

4. Login to ArgoCD and change password

    kubectl -n argocd port-forward svc/argocd-server 8443:443
    argocd login --username admin --password $(kubectl get pods -n argocd -l app.kubernetes.io/name=argocd-server -o name | cut -d'/' -f 2) localhost:8443
    argocd account update-password --current-password $(kubectl get pods -n argocd -l app.kubernetes.io/name=argocd-server -o name | cut -d'/' -f 2)

5. Trigger ArgoCD application syncs

    argocd app sync apps
    argocd app sync kube-system
    argocd app sync argocd

## Operations and maintenance

### Update Sealed Secrets

    export VERSION=v0.…
    curl -sLo kube-system/sealed-secrets.yaml "https://github.com/bitnami-labs/sealed-secrets/releases/download/${VERSION}/controller.yaml"

### Update ArgoCD

    curl -sLo argocd/argocd.yaml https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
    sed -i'' 's|argoproj/argocd:v1.7.9|alinbalutoiu/argocd:v1.7.10|g' argocd/argocd.yaml

ARM compatibilty of ArgoCD is not yet a given: https://github.com/argoproj/argo-cd/issues/4211.

### Update cert-manager

    export VERSION=v1.…
    curl -sLo cert-manager/cert-manager.yaml https://github.com/jetstack/cert-manager/releases/download/${VERSION}/cert-manager.yaml
