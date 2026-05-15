# Imagen base: misma que el ejemplo, Node 20 Alpine (ligera)
FROM node:20-alpine

# En qué carpeta vamos a trabajar
WORKDIR /app

# Copiamos primero package.json para aprovechar la cache de capas de Docker
# (si no cambian las dependencias, no vuelve a instalar)
COPY package*.json ./

# Instalamos las dependencias
RUN npm install --omit=dev

# Copiamos el resto del código
COPY . .

# Exponemos el puerto
EXPOSE 3000

# Ejecutamos la app
CMD ["node", "src/index.js"]
