# Innovatech Chile — DevOps EV3

Aplicacion full-stack desplegada en **Amazon EKS** con pipeline **CI/CD** automatizado.

---

## Arquitectura

| Componente | Tecnologia | Puerto |
|------------|------------|--------|
| Frontend | React + Vite + Nginx | 80 |
| Backend Ventas | Spring Boot | 8080 |
| Backend Despachos | Spring Boot | 8081 |
| API Node | Express | 3000 |
| Base de datos | MySQL (K8s) | 3306 |
| Orquestacion | Amazon EKS | — |
| Imagenes | Amazon ECR | — |

---

## Despliegue con un solo comando (infraestructura)

```bash
terraform init
terraform apply
```

Recursos que crea Terraform:

- VPC + subredes (incluye 2a subred publica para EKS en otra AZ)
- Clúster **EKS** (`innovatech-cluster`) + node group
- Repositorios **ECR** (`innovatech-poc-*`)
- Instancias EC2 legacy (lift-and-shift)

Conectar kubectl:

```bash
aws eks update-kubeconfig --name innovatech-cluster --region us-east-1
kubectl get nodes
```

---

## Pipeline CI/CD — Punto 2

Archivo: `.github/workflows/deploy.yml`

```
Push → Compilar → Build Docker → Push ECR → kubectl apply EKS → Validar
```

Se ejecuta al hacer push a `main` o `deploy`.

### Secrets requeridos (Settings → Secrets → Actions)

| Secret | Descripcion |
|--------|-------------|
| `AWS_ACCESS_KEY_ID` | Credencial AWS Academy |
| `AWS_SECRET_ACCESS_KEY` | Credencial AWS Academy |
| `AWS_SESSION_TOKEN` | Token de sesion AWS Academy |
| `AWS_ACCOUNT_ID` | ID de cuenta AWS (12 digitos) |

### Despliegue manual (sin pipeline)

```bash
export ECR_REGISTRY="<ACCOUNT_ID>.dkr.ecr.us-east-1.amazonaws.com"
export IMAGE_TAG="latest"
./scripts/deploy-k8s.sh
./scripts/validate-deployment.sh
```

---

## Manifiestos Kubernetes

Los deployments usan variables de imagen ECR:

```yaml
image: ${ECR_REGISTRY}/innovatech-poc-frontend:${IMAGE_TAG}
```

El script `deploy-k8s.sh` las sustituye con `envsubst` antes del `kubectl apply`.

---

## Verificacion funcional

```bash
kubectl get pods,svc -n innovatech
kubectl get svc frontend -n innovatech -o jsonpath='{.status.loadBalancer.ingress[0].hostname}'
```

---

## Analisis del pipeline — Punto 3

Ver documento: [`docs/PIPELINE-ANALISIS.md`](docs/PIPELINE-ANALISIS.md)

---

## Estructura

```
DevOps-/
├── .github/workflows/deploy.yml   # Pipeline CI/CD
├── infra/k8s/                     # Manifiestos Kubernetes
├── scripts/deploy-k8s.sh            # Deploy a EKS
├── scripts/validate-deployment.sh # Validacion post-deploy
├── eks.tf                         # Cluster EKS (VPC de main.tf)
├── ecr.tf                         # Repositorios ECR
├── main.tf                        # VPC, EC2, red
└── docs/PIPELINE-ANALISIS.md      # Analisis punto 3
```

---

## Destruir infraestructura

```bash
terraform destroy
```
