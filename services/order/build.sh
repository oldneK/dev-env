#!/bin/bash

docker compose exec order-service ./gradlew build jacocoTestReport

