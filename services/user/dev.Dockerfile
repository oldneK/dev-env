FROM gradle:8.6-jdk17

USER root

RUN mkdir -p /home/gradle/.gradle && chown -R gradle:gradle /home/gradle

USER gradle
WORKDIR /app

CMD ["./gradlew", "bootRun"]

