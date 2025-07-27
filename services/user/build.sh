#!/bin/bash

docker compose exec user-service ./gradlew build jacocoTestReport
