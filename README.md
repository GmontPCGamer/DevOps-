# Innovatech Chile — DevOps EV3

Guía de ejecución secuencial **End-to-End** para el despliegue full-stack en **Amazon EKS** con pipeline **CI/CD** automatizado. 
Documenta el aprovisionamiento de infraestructura, la federación del plano de control, la verificación de la malla de aplicaciones y la extracción de endpoints dinámicos de la capa de servicios.

---

## ETAPA 1: PREPARACIÓN E INFRAESTRUCTURA BASE (Terraform)

Crea la red (VPC), el clúster EKS y los repositorios ECR. Todos los valores de salida son dinámicos y se obtienen mediante `terraform output`.

```bash
terraform init
terraform validate
terraform plan
terraform apply --auto-approve
```
*(Tiempo estimado: ~15 minutos)*

### Verificación de Consistencia del Estado Local

Si durante una ejecución previa el recurso `aws_eks_node_group.innovatech_nodes` fue removido del estado local 
(p. ej. por un `terraform destroy` interrumpido) pero el Managed Node Group sigue existiendo en AWS, puedes reincorporarlo al `.tfstate`:

```bash
terraform import aws_eks_node_group.innovatech_nodes innovatech-cluster:innovatech-nodes
```

> **Nota:** Si el recurso ya se encuentra gestionado en el estado local, Terraform responderá con el error `"Resource already managed"`. 
Esto es un **indicador positivo de consistencia** y protección del `.tfstate`; no requiere ninguna acción adicional.

### Mitigación de Timeout en Node Group EKS

Durante el aprovisionamiento inicial puede ocurrir que `terraform apply` exceda el tiempo de espera local mientras AWS completa el Managed Node Group (~10-12 min totales). Esto no es un error: el plano de control de EKS continúa su creación autónomamente. Para recuperar la consistencia del estado local:

```bash
# Verificar que el clúster y los nodos estén activos en AWS
aws eks describe-cluster --name innovatech-cluster --region us-east-1 --query 'cluster.status'
aws eks describe-nodegroup --cluster-name innovatech-cluster --nodegroup-name innovatech-nodes --region us-east-1 --query 'nodegroup.status'

# Sincronizar estado de Terraform con la infraestructura real
terraform refresh

# Confirmar que todos los recursos (31) están registrados
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

---

## ETAPA 2: CONFIGURACIÓN Y CONEXIÓN AL PLANO DE CONTROL

### Actualizar Credenciales de AWS en GitHub Actions

Las credenciales de AWS Academy expiran cada 4 horas. Antes de ejecutar el pipeline, actualízalas en el repositorio:

1. Ve a **Settings > Secrets and variables > Actions**.
2. Actualiza los siguientes secretos con los valores de tu sesión *AWS Academy > AWS Details*:
   - `AWS_ACCESS_KEY_ID`
   - `AWS_SECRET_ACCESS_KEY`
   - `AWS_SESSION_TOKEN`
   - `AWS_ACCOUNT_ID` (ID de cuenta de 12 dígitos)

### Federación y Enlace al Clúster EKS

Configura `kubectl` y verifica que los nodos trabajadores estén operativos:

```bash
aws eks update-kubeconfig --name innovatech-cluster --region us-east-1
kubectl get nodes
```

Los nodos deben figurar en estado `Ready` con la versión `v1.32.x-eks-...`. 
Este comando no depende de valores estáticos; resuelve el endpoint del API server contra el plano de control de EKS en tiempo real.

---

## ETAPA 3: VERIFICACIÓN DEL DESPLIEGUE Y DESCUBRIMIENTO DE ENDPOINTS

La capa de aplicación se despliega en el namespace `innovatech`. 
Una vez que el pipeline CI/CD completa su ejecución, los pods y servicios están disponibles en el clúster.

### Auditoría Global de la Malla de Servicios

```bash
# Ver pods y servicios del namespace de aplicación
kubectl get pods,svc -n innovatech

# Mapear toda la arquitectura de red interna y externa del clúster
kubectl get svc --all-namespaces
```

### Endpoint del Frontend (LoadBalancer)

El servicio `frontend` expone la aplicación al exterior mediante un Elastic Load Balancer (ELB) de AWS. Para obtener la URL de acceso:

```bash
kubectl get svc frontend -n innovatech -o jsonpath='{.status.loadBalancer.ingress[0].hostname}'
```

> **Clave técnica:** Este comando **no retorna una IP estática**. 
Interroga a la API de Kubernetes para arrojar la **URL DNS dinámica** generada por el ELB de AWS, con la estructura `*.us-east-1.elb.amazonaws.com`. 
Esta URL varía en cada despliegue o laboratorio de AWS Academy y representa el punto de entrada único en el puerto 80 para consumir la aplicación desde el navegador o mediante `curl`.

```bash
# Ejemplo de uso de la URL dinámica
FRONTEND_URL=$(kubectl get svc frontend -n innovatech -o jsonpath='{.status.loadBalancer.ingress[0].hostname}')
curl -I "http://${FRONTEND_URL}"
```

### Microservicios Internos (ClusterIP)

Los microservicios que actúan detrás del API Gateway o balanceador están aislados mediante políticas **ClusterIP**, lo que restringe su acceso exclusivamente al plano de red interno de EKS. 
No responden a comandos ICMP (ping) por restricciones de seguridad perimetral.

| Servicio | Puerto Interno | Tipo | Acceso |
|---|---|---|---|
| `api-node` | 3000 | ClusterIP | Solo interno EKS |
| `back-ventas` | 8080 | ClusterIP | Solo interno EKS |
| `back-despachos` | 8081 | ClusterIP | Solo interno EKS |
| `mysql` | 3306 | ClusterIP | Solo interno EKS |

Para verificar la resolución interna desde un pod efímero:

```bash
kubectl run -n innovatech --rm -it test-pod --image=busybox -- sh
# Dentro del pod:
wget -qO- http://api-node:3000/health
wget -qO- http://back-ventas:8080/health
ping api-node  # No responderá (política ClusterIP + restricción ICMP)
```

### Comandos de Verificación por CLI

Para validar la infraestructura base independientemente del estado de la capa de aplicación:

```bash
# Validar nodos del clúster EKS
kubectl get nodes

# Verificar la existencia física del Log Group de CloudWatch
aws logs describe-log-groups --log-group-name-prefix "/eks/innovatech-poc" --region us-east-1

# Confirmar login a los repositorios ECR
aws ecr get-login-password --region us-east-1 | docker login --username AWS --password-stdin $(terraform output -raw ecr_frontend_url | cut -d'/' -f1)

# Consultar outputs del estado de Terraform
terraform output
```

*(Nota técnica: El Log Group puede mostrar 0 bytes almacenados si no se han desplegado agentes recolectores o pods en el clúster. 
Los mensajes visuales como "Failed to load tag-based configurations" en la consola web son propios de las restricciones de la política `voc-cancel-cred` del laboratorio AWS Academy y no representan fallas en la configuración del recurso. 
La API por CLI responde correctamente.)*

---

## ETAPA 4: CIERRE Y DESTRUCCIÓN

### Destruir Infraestructura

Para no consumir más créditos de AWS Academy al finalizar la evaluación:

```bash
terraform destroy --auto-approve
```

> **Limitación conocida:** La política `voc-cancel-cred` del laboratorio AWS Academy puede bloquear las operaciones de lectura necesarias para que Terraform planifique el destroy 
(`eks:DescribeCluster`, `ecr:DescribeRepositories`, `ec2:DescribeInstances`, `iam:GetRole`, `logs:DescribeLogGroups`). 
Si el comando falla, renueva las credenciales AWS Academy e intenta nuevamente. Como workaround, los recursos pueden eliminarse manualmente desde la consola AWS.

### Documentación Complementaria

El análisis detallado del pipeline CI/CD (tiempos, optimizaciones implementadas y oportunidades de mejora) está disponible en:
**[docs/PIPELINE-ANALISIS.md](docs/PIPELINE-ANALISIS.md)**