# Etapa 1: compila a aplicacao usando Maven e gera o arquivo .jar.
FROM maven:3.9.9-eclipse-temurin-17 AS build

WORKDIR /app

# Copia primeiro o pom.xml para aproveitar cache de dependencias entre builds.
COPY pom.xml .
RUN mvn dependency:go-offline -B

# Copia o codigo-fonte e executa o empacotamento.
COPY src ./src
RUN mvn clean package -DskipTests

# Etapa 2: imagem final menor, contendo apenas o JRE e o .jar compilado.
FROM eclipse-temurin:17-jre-alpine

WORKDIR /app

# Usuario sem privilegios para executar a aplicacao com mais seguranca.
RUN addgroup -S greenpulse && adduser -S greenpulse -G greenpulse

COPY --from=build /app/target/*.jar app.jar

RUN chown -R greenpulse:greenpulse /app
USER greenpulse

EXPOSE 8080

# Executa a aplicacao Spring Boot.
ENTRYPOINT ["java", "-jar", "app.jar"]
