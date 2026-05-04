# Innovatech - Infraestructura como Código (MiniStack)

Repositorio de infraestructura para el proyecto **DevOps-** desplegado sobre un entorno de laboratorio **MiniStack** (LocalStack). 
La arquitectura sigue un modelo de tres capas con aislamiento estricto de red y salida a internet controlada mediante NAT Gateway.

## Arquitectura

### Topología de Red

```
┌─────────────────────────────────────────────────────────────┐
│                         VPC 10.0.0.0/16                     │
│  ┌─────────────────────────┐   ┌────────────────────────────┐ │
│  │    Subred Pública       │   │    Subred Privada          │ │
│  │    10.0.1.0/24          │   │    10.0.2.0/24            │ │
│  │                         │   │                            │ │
│  │  ┌─────────────────┐    │   │  ┌─────────────────┐       │ │
│  │  │  ECS Frontend   │◄───┼───┼──┤  ECS Backend    │       │ │
│  │  │  (Fargate)      │    │   │  │  (Fargate)      │       │ │
│  │  │  SG: FrontSG    │    │   │  │  SG: BackSG     │       │ │
│  │  │  Puerto: 80/443 │    │   │  │  Puerto: 8080   │       │ │
│  │  └────────┬────────┘    │   │  └────────┬────────┘       │ │
│  │           │             │   │           │                │ │
│  │     Internet Gateway    │   │      NAT Gateway           │ │
│  │           ▲             │   │           │                │ │
│  └───────────┼─────────────┘   └───────────┼────────────────┘ │
│              │                             │                  │
│         Usuario Local                 Salida a Internet      │
│       (localhost:4566)              (dependencias, DockerHub) │
│                                                              │
│  Base de Datos (capa Data): Puerto 3306 desde BackSG         │
└─────────────────────────────────────────────────────────────┘
```

### Flujo de Tráfico

- **Frontend** (Subred Pública): Recibe tráfico HTTP/HTTPS desde internet (o localhost en MiniStack). Tiene acceso directo a internet vía Internet Gateway.
- **Backend** (Subred Privada): **Solo acepta tráfico entrante del Security Group Frontend en el puerto 8080**. No tiene IP pública; su salida a internet es exclusivamente a través del NAT Gateway (descarga de dependencias, imágenes Docker, etc.).
- **Database** (Subred Privada): **Solo acepta tráfico del Security Group Backend en el puerto 3306**. Sin acceso directo a internet.

## Requisitos Previos

- [Terraform](https://developer.hashicorp.com/terraform/downloads) >= 1.5.0
- [LocalStack](https://localstack.cloud/) o MiniStack ejecutándose en `http://localhost:4566`
- [AWS CLI](https://aws.amazon.com/cli/)

## Despliegue

### 1. Inicializar Terraform

```bash
terraform init
```

### 2. Validar configuración

```bash
terraform validate
```

### 3. Generar y revisar plan

```bash
terraform plan
```

### 4. Aplicar infraestructura

```bash
terraform apply
```

> Confirma con `yes` cuando se solicite.

### 5. Verificar recursos con AWS CLI (MiniStack)

Configurar el endpoint local:

```bash
aws configure set region us-east-1
export AWS_ENDPOINT_URL=http://localhost:4566
```

Listar repositorios ECR:

```bash
aws ecr describe-repositories --endpoint-url http://localhost:4566
```

Listar cluster ECS:

```bash
aws ecs list-clusters --endpoint-url http://localhost:4566
```

Describir servicios ECS:

```bash
aws ecs describe-services --cluster DevOps--cluster --services DevOps--frontend-service DevOps--backend-service --endpoint-url http://localhost:4566
```

Listar VPC y subredes:

```bash
aws ec2 describe-vpcs --endpoint-url http://localhost:4566
aws ec2 describe-subnets --endpoint-url http://localhost:4566
```

### 6. Destruir infraestructura

```bash
terraform destroy
```

## Recursos Desplegados

| Recurso | Descripción |
|---------|-------------|
| `aws_vpc.main` | VPC `10.0.0.0/16` con DNS habilitado |
| `aws_subnet.public_frontend` | Subred pública `10.0.1.0/24` (Frontend) |
| `aws_subnet.private_backend_data` | Subred privada `10.0.2.0/24` (Backend / Data) |
| `aws_nat_gateway.nat` | NAT Gateway para salida segura de subred privada |
| `aws_security_group.sg_front` | Acceso 80/443 desde `0.0.0.0/0` |
| `aws_security_group.sg_back` | Acceso 8080 **solo desde `sg_front`** |
| `aws_security_group.sg_data` | Acceso 3306 **solo desde `sg_back`** |
| `aws_ecr_repository.frontend` | Registro de imágenes del Frontend (`force_delete = true`) |
| `aws_ecr_repository.backend` | Registro de imágenes del Backend (`force_delete = true`) |
| `aws_ecs_cluster.main` | Cluster ECS para orquestación Fargate |
| `aws_ecs_service.frontend` | Servicio ECS Frontend (público, IP asignada) |
| `aws_ecs_service.backend` | Servicio ECS Backend (privado, sin IP pública) |

## Etiquetas (Tags) Globales

Todos los recursos heredan:

- `Proyecto = DevOps-`
- `Ambiente = Local-MiniStack`
- `Owner = Emilio Hormazabal, Patricio Carvajal, Genesis Flores`
- `ManagedBy = Terraform`

## Próximos Pasos

### Contenedorización de Servicios

Para completar el ciclo de despliegue, los siguientes componentes deben ser empaquetados como imágenes Docker y subidos a los repositorios ECR locales:

1. **Backend Java (Spring Boot)**
   - Empaquetar la aplicación con Maven/Gradle.
   - Crear `Dockerfile` basado en imagen ligera (eclipse-temurin, Amazon Corretto).
   - Exponer puerto `8080`.
   - Push al repositorio ECR: `DevOps--backend`.

2. **Base de Datos MySQL**
   - Utilizar imagen oficial `mysql:latest` o versión fija.
   - Configurar variables de entorno (`MYSQL_ROOT_PASSWORD`, `MYSQL_DATABASE`).
   - Exponer puerto `3306`.
   - Considerar volumen persistente para datos (volumen Docker o bind mount en desarrollo).

3. **Frontend**
   - Empaquetar aplicación web (React, Angular, Vue, etc.) en servidor nginx o similar.
   - Exponer puerto `80`.
   - Push al repositorio ECR: `DevOps--frontend`.

4. **Pipeline CI/CD**
   - Automatizar `docker build` y `docker push` hacia `localhost:4566` (ECR local).
   - Actualizar las Task Definitions de ECS para apuntar a los nuevos tags de imagen.
   - Ejecutar `terraform apply` para redeploy de servicios.

## Mensaje de Commit Sugerido

```text
feat(infra): despliegue base VPC, ECS y ECR en MiniStack

- Configura provider AWS apuntando a localhost:4566 con flags de escape
  para entorno LocalStack/MiniStack.
- Crea VPC 10.0.0.0/16 con subred pública (Front) y privada (Back/Data).
- Implementa NAT Gateway para salida controlada de subred privada.
- Define Security Groups encadenados:
  * Front: 80/443 desde 0.0.0.0/0
  * Back: 8080 únicamente desde FrontSG
  * Data: 3306 únicamente desde BackSG
- Añade repositorios ECR (frontend/backend) con force_delete=true.
- Despliega cluster ECS con Task Definitions Fargate y Services
  para frontend (público) y backend (privado).
- Aplica tags globales: Proyecto=DevOps-, Ambiente=Local-MiniStack,
  Owner=Emilio Hormazabal, Patricio Carvajal, Genesis Flores.

Refs: feature/deploy-ministack
```
