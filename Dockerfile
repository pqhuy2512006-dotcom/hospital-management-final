FROM eclipse-temurin:21-jdk AS build
WORKDIR /app
COPY . .
RUN chmod +x mvnw && ./mvnw -B clean package -DskipTests

FROM eclipse-temurin:21-jre
WORKDIR /app
COPY --from=build /app/target/hospital-management-0.0.1-SNAPSHOT.jar app.jar
CMD ["sh", "-c", "java -Dserver.port=${PORT:-8080} -jar app.jar"]