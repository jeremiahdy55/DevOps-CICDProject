# Use a Maven image to build the application
FROM maven:3.8.7-eclipse-temurin-17 AS build

# Set the working directory inside the container
WORKDIR /app

# Copy the pom.xml and download dependencies (layered to optimize build cache)
COPY pom.xml .

# Download the dependencies
RUN mvn dependency:go-offline -B

# Copy the entire project source code
COPY src ./src

# Package the application
RUN mvn clean package -DskipTests

# Use an OpenJDK image to run the application
FROM openjdk:17-jdk

# Set the working directory inside the container
WORKDIR /app

# Create logs directory
RUN mkdir /app/logs

# Copy the packaged jar file from the build stage
COPY --from=build /app/target/order-ms-0.0.1-SNAPSHOT.jar  /app/order-ms-0.0.1-SNAPSHOT.jar

# Expose the application port
EXPOSE 8081

# Run the application
CMD ["sh","-c","java -jar order-ms-0.0.1-SNAPSHOT.jar > /app/logs/app.log 2>&1"]