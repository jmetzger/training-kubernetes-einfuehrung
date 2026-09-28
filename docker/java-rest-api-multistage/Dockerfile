# Stage 1: Build - hier steht der komplette JDK-Compiler zur Verfuegung
FROM eclipse-temurin:21-jdk-alpine AS build
WORKDIR /app
COPY Main.java .
RUN javac Main.java

# Stage 2: Runtime - nur die fertige .class-Datei + schlankes JRE
FROM eclipse-temurin:21-jre-alpine
WORKDIR /app
COPY --from=build /app/Main*.class .
EXPOSE 8080
CMD ["java", "Main"]
