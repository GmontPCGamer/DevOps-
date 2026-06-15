#!/usr/bin/env bash
# Despliega la aplicacion Innovatech Chile en EKS.
# Variables requeridas: ECR_REGISTRY, IMAGE_TAG (opcional: K8S_NAMESPACE)

set -euo pipefail

NAMESPACE="${K8S_NAMESPACE:-innovatech}"
ECR_REGISTRY="${ECR_REGISTRY:?ECR_REGISTRY no definido}"
IMAGE_TAG="${IMAGE_TAG:-latest}"

export ECR_REGISTRY IMAGE_TAG

echo "==> Namespace: ${NAMESPACE}"
echo "==> ECR: ${ECR_REGISTRY}"
echo "==> Tag: ${IMAGE_TAG}"

render_deployment() {
  envsubst '${ECR_REGISTRY} ${IMAGE_TAG}' < "$1"
}

apply_ordered() {
  kubectl apply -f infra/k8s/namespace/
  kubectl apply -f infra/k8s/secrets/
  kubectl apply -f infra/k8s/configmaps/
  kubectl apply -f infra/k8s/mysql/

  render_deployment infra/k8s/back-ventas/deployment.yaml | kubectl apply -f -
  kubectl apply -f infra/k8s/back-ventas/service.yaml

  render_deployment infra/k8s/back-despachos/deployment.yaml | kubectl apply -f -
  kubectl apply -f infra/k8s/back-despachos/service.yaml

  render_deployment infra/k8s/api-node/deployment.yaml | kubectl apply -f -
  kubectl apply -f infra/k8s/api-node/service.yaml

  render_deployment infra/k8s/frontend/deployment.yaml | kubectl apply -f -
  kubectl apply -f infra/k8s/frontend/service.yaml
}

wait_rollout() {
  echo "==> Esperando rollout: $1"
  kubectl rollout status "deployment/$1" -n "${NAMESPACE}" --timeout="${2:-300s}"
}

apply_ordered
wait_rollout mysql 300s
wait_rollout back-ventas 420s
wait_rollout back-despachos 420s
wait_rollout api-node 180s
wait_rollout frontend 180s

echo "==> Despliegue completado."
kubectl get pods,svc -n "${NAMESPACE}"
