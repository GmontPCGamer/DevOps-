# API Innovatech — Ventas & Despachos

API REST construida con Node.js + Express y contenida en Docker.  
Modela los módulos de **Ventas** y **Despachos** del sistema Innovatech Chile.

---

## 📁 Estructura del proyecto

```
api-innovatech/
├── src/
│   ├── index.js                  # Punto de entrada, middlewares, arranque
│   ├── routes/
│   │   ├── ventas.routes.js      # CRUD de ventas
│   │   └── despachos.routes.js   # CRUD de despachos
│   └── data/
│       ├── ventas.data.js        # Datos en memoria (mock)
│       └── despachos.data.js     # Datos en memoria (mock)
├── .dockerignore
├── .env.example
├── .gitignore
├── Dockerfile
├── docker-compose.yml
└── package.json
```

---

## 🚀 Cómo correr el proyecto

### Opción A — Con Docker Compose (recomendado)

```bash
# 1. Construir la imagen y levantar el contenedor
docker compose up --build

# 2. Detener
docker compose down
```

### Opción B — Con Docker directamente

```bash
# 1. Construir la imagen
docker build -t api-innovatech .

# 2. Correr el contenedor
docker run -d -p 3000:3000 --name api-innovatech api-innovatech

# 3. Ver logs
docker logs -f api-innovatech

# 4. Detener y eliminar
docker stop api-innovatech && docker rm api-innovatech
```

### Opción C — Sin Docker (local)

```bash
cp .env.example .env
npm install
npm start
```

---

## 🧪 Cómo probar la API

Una vez levantada, la API corre en `http://localhost:3000`.

### Health check

```bash
curl http://localhost:3000/health
```

---

### Ventas — `GET /api/v1/ventas`

```bash
# Listar todas las ventas
curl http://localhost:3000/api/v1/ventas

# Obtener venta por ID
curl http://localhost:3000/api/v1/ventas/1

# Crear nueva venta
curl -X POST http://localhost:3000/api/v1/ventas \
  -H "Content-Type: application/json" \
  -d '{"cliente":"Tienda Norte","producto":"Auriculares","cantidad":3,"precioUnit":29990}'

# Eliminar una venta
curl -X DELETE http://localhost:3000/api/v1/ventas/1
```

---

### Despachos — `GET /api/v1/despachos`

```bash
# Listar todos los despachos
curl http://localhost:3000/api/v1/despachos

# Obtener despacho por ID
curl http://localhost:3000/api/v1/despachos/1

# Obtener despacho por ventaId
curl http://localhost:3000/api/v1/despachos/venta/2

# Crear nuevo despacho
curl -X POST http://localhost:3000/api/v1/despachos \
  -H "Content-Type: application/json" \
  -d '{"ventaId":1,"direccion":"Los Aromos 22, Temuco","transportista":"Correos Chile"}'

# Actualizar estado del despacho
curl -X PATCH http://localhost:3000/api/v1/despachos/1/estado \
  -H "Content-Type: application/json" \
  -d '{"estado":"en_tránsito"}'
```

---

## 📋 Endpoints disponibles

| Método   | Ruta                               | Descripción                  |
|----------|------------------------------------|------------------------------|
| `GET`    | `/health`                          | Estado del servicio          |
| `GET`    | `/api/v1/ventas`                   | Listar todas las ventas      |
| `GET`    | `/api/v1/ventas/:id`               | Obtener venta por ID         |
| `POST`   | `/api/v1/ventas`                   | Crear nueva venta            |
| `DELETE` | `/api/v1/ventas/:id`               | Eliminar venta               |
| `GET`    | `/api/v1/despachos`                | Listar todos los despachos   |
| `GET`    | `/api/v1/despachos/:id`            | Obtener despacho por ID      |
| `GET`    | `/api/v1/despachos/venta/:ventaId` | Despacho asociado a una venta|
| `POST`   | `/api/v1/despachos`                | Crear nuevo despacho         |
| `PATCH`  | `/api/v1/despachos/:id/estado`     | Actualizar estado del despacho|
