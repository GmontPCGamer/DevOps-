# ── Etapa 1: build ────────────────────────────────────────────────────────────
# Usamos Node para compilar la app React con Vite
FROM node:20-alpine AS build

WORKDIR /app

# Copiamos dependencias primero (aprovecha cache de capas)
COPY package*.json ./
RUN npm install

# Copiamos el resto del código y compilamos
COPY . .
RUN npm run build

# ── Etapa 2: producción ────────────────────────────────────────────────────────
# Solo copiamos el resultado del build a Nginx (imagen mucho más liviana)
FROM nginx:alpine

# Copiamos los archivos compilados al directorio de Nginx
COPY --from=build /app/dist /usr/share/nginx/html

EXPOSE 80

CMD ["nginx", "-g", "daemon off;"]
