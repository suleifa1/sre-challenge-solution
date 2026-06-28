# ==========STAGE 1: Build the app ==============
FROM gradle:8.5-jdk21 AS builder

WORKDIR /build

COPY gradlew .
COPY gradle gradle
COPY build.gradle .
COPY settings.gradle .
COPY gradle.properties .
COPY app/build.gradle app/build.gradle
COPY app/common app/common
COPY app/front app/front

RUN ./gradlew :app:front:build -x test --no-daemon

# ==========STAGE 2: Run the app ==============


FROM ibm-semeru-runtimes:open-21-jre

ARG JAR_VERSION=0.1.0
COPY --from=builder /build/app/front/build/libs/front-${JAR_VERSION}.jar /app.jar

ENTRYPOINT ["java", "-Djava.security.egd=file:/dev/./urandom", "-jar", "/app.jar"]
