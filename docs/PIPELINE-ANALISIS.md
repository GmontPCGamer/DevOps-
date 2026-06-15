# Analisis del Pipeline CI/CD — Punto 3

Documento para la evaluacion: analisis de desempeno, tiempos y oportunidades de mejora.

---

## Flujo del pipeline (`deploy.yml`)

| Job | Funcion | Dependencia |
|-----|---------|-------------|
| `build` | Compila Node, React y Spring Boot | — |
| `docker-push` | Build + push 4 imagenes a ECR (paralelo) | build |
| `deploy-eks` | kubectl apply + rollout en EKS | docker-push |
| `validate` | Health checks + Load Balancer | deploy-eks |

---

## Metricas a registrar (desde GitHub Actions)

Completar tras ejecutar el pipeline al menos una vez:

| Job | Tiempo estimado | Tiempo real | Observaciones |
|-----|-----------------|-------------|---------------|
| build | ~2-4 min | ___ min | Maven es el paso mas lento |
| docker-push (x4) | ~5-8 min | ___ min | Paralelo con matrix |
| deploy-eks | ~8-12 min | ___ min | Rollout Spring Boot tarda |
| validate | ~2-3 min | ___ min | Espera del Load Balancer |
| **Total** | ~17-27 min | ___ min | |

---

## Optimizaciones ya implementadas

1. **Builds Docker en paralelo** — matrix de 4 servicios en lugar de jobs secuenciales.
2. **Cache de capas Docker** — `cache-from` / `cache-to` con GitHub Actions cache (GHA).
3. **Cancelacion de runs duplicados** — `concurrency` evita pipelines solapados.
4. **Tag por commit SHA** — trazabilidad imagen ↔ codigo desplegado.
5. **Compilacion previa al Docker build** — detecta errores antes de construir imagenes.

---

## Oportunidades de mejora futuras

| Mejora | Impacto | Complejidad |
|--------|---------|-------------|
| Cache de dependencias Maven (`~/.m2`) | -2 min en build | Baja |
| Cache de `node_modules` | -1 min en build | Baja |
| Tests unitarios en CI (no skip) | Calidad | Media |
| Blue/green con Argo Rollouts | Zero downtime | Alta |
| Helm charts en lugar de YAML plano | Mantenibilidad | Media |
| AWS RDS en lugar de MySQL en K8s | Produccion real | Media |

---

## Errores comunes y solucion

| Error | Causa | Solucion |
|-------|-------|----------|
| `403 ECR` | Credenciales expiradas (Academy) | Renovar secrets en GitHub |
| `ImagePullBackOff` | Imagen no existe en ECR | Verificar push en job docker-push |
| Rollout timeout Spring Boot | MySQL no listo | Orden de deploy: mysql primero |
| LB sin hostname | AWS tarda en provisionar | validate espera hasta 300s |

---

## Conclusion para defensa tecnica (Punto 4)

El pipeline demuestra el flujo completo **commit → build → push ECR → deploy EKS → servicio operativo**.

Para la presentacion de 10-15 minutos:

1. Mostrar `deploy.yml` y explicar los 4 jobs (2 min).
2. Ejecutar push a `deploy` y mostrar Actions en vivo (5 min).
3. `kubectl get pods` + URL del Load Balancer (3 min).
4. Presentar esta tabla de tiempos y optimizaciones (3 min).
