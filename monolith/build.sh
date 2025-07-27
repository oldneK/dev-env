#!/bin/bash

docker compose exec monolith ./gradlew build jacocoTestReport

