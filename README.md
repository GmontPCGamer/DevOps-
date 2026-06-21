# Innovatech Chile — DevOps EV3

Guía rápida para la evaluación. Despliegue de aplicación full-stack en **Amazon EKS** con pipeline **CI/CD** automatizado.

---

## 1. Levantar Infraestructura (Terraform)
Crea la red (VPC), clúster EKS y repositorios ECR.

```bash
terraform init
terraform validate
terraform plan
terraform apply --auto-approve
```
*(Tiempo estimado: ~15 minutos)*

> **Nota:** Si el node group de EKS se elimina del estado de Terraform (ej: durante un `destroy` fallido) pero sigue existiendo en AWS, impórtalo nuevamente:
> ```bash
> terraform import aws_eks_node_group.innovatech_nodes innovatech-cluster:innovatech-nodes
> ```

### Mitigación de Timeout en Node Group EKS
Durante el aprovisionamiento inicial puede ocurrir que `terraform apply` exceda el tiempo de espera local mientras AWS completa el Managed Node Group (~10-12 min totales). Esto no es un error: el plano de control de EKS continúa su creación autónomamente. Para recuperar la consistencia del estado local:

```bash
# Verificar que el clúster y los nodos estén activos en AWS
aws eks describe-cluster --name innovatech-cluster --region us-east-1 --query 'cluster.status'
aws eks describe-nodegroup --cluster-name innovatech-cluster --nodegroup-name innovatech-nodes --region us-east-1 --query 'nodegroup.status'

# Sincronizar estado de Terraform con la infraestructura real
terraform refresh

# Confirmar que todos los recursos están registrados
terraform state list

# Conectarse al clúster y validar nodos listos
aws eks update-kubeconfig --name innovatech-cluster --region us-east-1
kubectl get nodes
```

### Secuencia Lógica de Aprovisionamiento
Terraform respeta un orden de dependencias implícito y explícito que garantiza la integridad del despliegue bajo la estrategia **Lift-&-Shift** hacia AWS Academy con el LabRole corporativo:

1. **Red Base** — VPC (`10.0.0.0/16`), subred pública frontend (`10.0.1.0/24`, us-east-1a), subred pública EKS (`10.0.3.0/24`, us-east-1b), subred privada backend/data (`10.0.2.0/24`, us-east-1a), Internet Gateway, NAT Gateway y Elastic IP.
2. **Seguridad** — Security Groups en cascada: `sg_front` (HTTP/80, SSH/22), `sg_back` (tráfico completo desde frontend), `sg_data` (puerto 5432 desde backend), `sg_eks` (tráfico interno y HTTPS desde VPC). Simultáneamente se resuelve el bloque `data.aws_iam_role.lab_role` para las políticas de ejecución.
3. **Cómputo Base** — 3 Launch Templates con user-data que instalan Docker, git y PostgreSQL. Las instancias EC2 frontend, backend y data se crean sobre estos templates.
4. **Registros ECR** — 4 repositorios privados (`frontend`, `back-ventas`, `back-despachos`, `api-node`) creados en paralelo con el clúster EKS.
5. **Orquestación EKS** — Clúster `innovatech-cluster` versión 1.32 con endpoint público. Una vez activo, se despliega el Managed Node Group con 2 nodos `t3.medium` (escalable entre 2 y 4) y sus reglas de autoscaling. El Log Group de CloudWatch (`/eks/innovatech-poc/applications`) completa el ciclo con retención de 7 días.

Conectar tu terminal al clúster recién creado:
```bash
aws eks update-kubeconfig --name innovatech-cluster --region us-east-1
kubectl get nodes

# Obtener la IP pública actual del frontend (puede cambiar tras reinicios)
terraform output frontend_public_ip
```

---

## 2. Actualizar Credenciales de AWS
Las credenciales de AWS Academy expiran cada 4 horas. Antes de ejecutar el pipeline, actualízalas en GitHub:
1. Ve a **Settings > Secrets and variables > Actions** en tu repositorio.
2. Actualiza los siguientes secretos con los datos de tu *AWS Details*:
   - `AWS_ACCESS_KEY_ID`
   - `AWS_SECRET_ACCESS_KEY`
   - `AWS_SESSION_TOKEN`
   - `AWS_ACCOUNT_ID` (Tu ID de cuenta de 12 dígitos)

---

## 3. Ejecutar Pipeline CI/CD (Despliegue)
El pipeline compila el código, crea imágenes Docker, las sube a ECR y despliega en Kubernetes.

1. Ve a la pestaña **Actions** en GitHub.
2. Selecciona **Deploy Innovatech — EKS** en el menú izquierdo.
3. Haz clic en **Run workflow** -> selecciona la rama `deploy` -> **Run workflow**.

*(Tiempo estimado: ~10 minutos)*

---

## 4. Verificar Despliegue
Una vez que el pipeline termine con éxito, ejecuta:

```bash
# Ver que todos los servicios estén corriendo (Running)
kubectl get pods,svc -n innovatech

# Obtener la URL pública (Load Balancer) del Frontend para probar en el navegador
kubectl get svc frontend -n innovatech -o jsonpath='{.status.loadBalancer.ingress[0].hostname}'
```

### Comandos de Verificación por CLI
Para validar la infraestructura base independientemente del estado de la capa de aplicación:

```bash
# Validar nodos del clúster EKS
kubectl get nodes

# Verificar la existencia física del Log Group de CloudWatch
aws logs describe-log-groups --log-group-name-prefix "/eks/innovatech-poc" --region us-east-1

# Confirmar login a los repositorios ECR
aws ecr get-login-password --region us-east-1 | docker login --username AWS --password-stdin 339712887424.dkr.ecr.us-east-1.amazonaws.com

# Consultar outputs del estado de Terraform
terraform output
```

*(Nota técnica: El Log Group puede mostrar 0 bytes almacenados si no se han desplegado agentes recolectores o pods en el clúster. Los mensajes visuales como "Failed to load tag-based configurations" en la consola web son propios de las restricciones de la política `voc-cancel-cred` del laboratorio AWS Academy y no representan fallas en la configuración del recurso. La API por CLI responde correctamente.)*

---

## 5. Análisis del Pipeline (Evaluación y Mejora)
Para la parte teórica de la evaluación, los tiempos, optimizaciones implementadas y oportunidades de mejora están documentados en:
**[Ver Documento de Análisis (docs/PIPELINE-ANALISIS.md)](docs/PIPELINE-ANALISIS.md)**

---

## 6. Destruir Infraestructura (Al finalizar)
Para no consumir más créditos de AWS Academy:
```bash
terraform destroy --auto-approve
```

> **Limitación conocida:** La política `voc-cancel-cred` del laboratorio AWS Academy puede bloquear operaciones de lectura necesarias para `terraform destroy` (EKS:DescribeCluster, ECR:DescribeRepositories, EC2:DescribeInstances, IAM:GetRole). Si el destroy falla, actualiza las credenciales AWS Academy e intenta nuevamente. Como workaround, los recursos pueden eliminarse manualmente desde la consola AWS.
