#!/bin/bash

set -e

CLUSTER_NAME="demo"
NAMESPACE="demo"
RELEASE_NAME="demo"
IMAGE_NAME="enterprisebot-service:v1"

echo "==> Checking kind cluster"

if kind get clusters | grep -q "^${CLUSTER_NAME}$"; then
    echo "Kind cluster ${CLUSTER_NAME} already exists"
else
    echo "Creating kind cluster ${CLUSTER_NAME}"
    kind create cluster --name ${CLUSTER_NAME}
fi


echo "==> Installing ingress-nginx"

if kubectl get namespace ingress-nginx >/dev/null 2>&1; then
    echo "Ingress namespace already exists"
else
    echo "Installing ingress-nginx controller"

    kubectl apply -f \
    https://raw.githubusercontent.com/kubernetes/ingress-nginx/main/deploy/static/provider/kind/deploy.yaml
fi


echo "==> Waiting for ingress controller"

kubectl rollout status \
    deployment/ingress-nginx-controller \
    -n ingress-nginx \
    --timeout=180s


echo "==> Building Docker image"

docker build \
    -t ${IMAGE_NAME} \
    ./service


echo "==> Loading image into kind cluster"

kind load docker-image \
    ${IMAGE_NAME} \
    --name ${CLUSTER_NAME}


echo "==> Creating namespace ${NAMESPACE}"

kubectl create namespace ${NAMESPACE} \
    --dry-run=client \
    -o yaml | kubectl apply -f -


echo "==> Installing Helm chart"

helm upgrade --install \
    ${RELEASE_NAME} \
    ./chart \
    --namespace ${NAMESPACE} \
    --set image.repository=enterprisebot-service \
    --set image.tag=v1


echo "==> Waiting for application rollout"

sleep 5

DEPLOYMENT_NAME=$(kubectl get deployments \
    -n ${NAMESPACE} \
    -o jsonpath='{.items[0].metadata.name}')

echo "Found deployment: ${DEPLOYMENT_NAME}"

kubectl rollout status \
    deployment/${DEPLOYMENT_NAME} \
    -n ${NAMESPACE} \
    --timeout=120s


echo ""
echo "====================================="
echo "Setup completed successfully"
echo "====================================="
echo ""

echo "Application pods:"
kubectl get pods -n ${NAMESPACE}

echo ""

echo "Ingress:"
kubectl get ingress -n ${NAMESPACE}
