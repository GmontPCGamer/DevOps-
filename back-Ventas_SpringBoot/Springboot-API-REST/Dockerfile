# ── Etapa 1: build ────────────────────────────────────────────────────────────
# Maven compila y genera el JAR
FROM maven:3.9-eclipse-temurin-17 AS build

WORKDIR /app

# Copiamos pom.xml primero (aprovecha cache de capas)
COPY pom.xml ./
RUN mvn dependency:go-offline -q

# Copiamos el código fuente y compilamos (sin tests)
COPY src ./src
RUN mvn package -DskipTests -q

# ── Etapa 2: producción ────────────────────────────────────────────────────────
# Solo el JRE, sin Maven ni código fuente (imagen mucho más liviana)
FROM eclipse-temurin:17-jre-alpine

WORKDIR /app

# Copiamos únicamente el JAR generado
COPY --from=build /app/target/*.jar app.jar

EXPOSE 8080

CMD ["java", "-jar", "app.jar"]
