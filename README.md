# Developer Onboarding & Local Development Improvement Prototype

## 1. Problem Framing

### 1.1. Main Pain Points
- The onboarding process takes too long
- Setting up local dev environments is too complicated
- Difficulty running database locally
- Integration tests are inconsistent and hard to run

---

### 1.2. Users and Their Needs
- **New engineers**:  
  - Need to build a local environment as quickly as possible and be able to start development immediately.

- **QA engineers**:  
  - Need an environment that is highly reproducible and allows for reliable testing.

- **SRE/infrastructure engineers**:  
  - Want to eliminate differences in environments between engineers and reduce operational burden.

---

## 2. Proposed Solution

### 2.1. Overview
- This solution simplifies the onboarding process for Spring Boot microservices by introducing a script-driven and containerized dev environment.  
It enables selective service startup and supports hot-reloading for efficient development.

---

### 2.2. Tools or Approaches Introduced

#### `onboard.sh` Bash Script

A unified onboarding script that allows developers to start only the required microservices by specifying service names as arguments.
This improves performance and reduces startup time for development.

* **Reasoning**:
  - Allowing developers to start only the necessary services (e.g., `onboard.sh user`, 
  `onboard.sh monolith order`) significantly speeds up onboarding and conserves system resources.

* **Tradeoffs**:
  - In tightly coupled systems, running partial services may break inter-service communication
  or result in missing data. Documentation and mock strategies may be required for smoother onboarding.

---

#### Docker-Based Environment

All services run inside Docker containers, including a shared MySQL container for local database usage.
This ensures consistency across environments and reduces “it works on my machine” issues.

* **Reasoning**:
  - Docker ensures a consistent environment across developers’ machines, reducing
  “works on my machine” issues. It also isolates dependencies and removes the need
  to install local runtimes like MySQL or JDK.

* **Tradeoffs**:
  - Docker introduces a learning curve and may cause performance overhead, especially on
  macOS or Windows. Developers unfamiliar with Docker might need onboarding support.

---

#### Volume Mounting for Live Development

Source code is edited on the host machine and mounted into the container using Docker volumes.
This allows for real-time synchronization of code changes without rebuilding the image.

* **Reasoning**:
  - The host machine’s source code is mounted into the container, allowing developers
  to use their preferred local tools while the containerized environment reflects changes in real time.

* **Tradeoffs**:
  - File sync performance may degrade under heavy I/O or on non-Linux systems
  such as macOS or Windows using Docker Desktop.

---

#### Spring Boot DevTools

DevTools is enabled inside each container to detect file changes and trigger automatic hot-reloading,
resulting in a fast feedback loop during local development.

* **Reasoning**:
  - DevTools monitors classpath changes and reloads affected parts of the application automatically.
  - Combined with volume mounting, this offers a smooth development loop without full restarts.

* **Tradeoffs**:
  - DevTools may not detect changes to static resources.
  - IDEs or custom build setups may require configuration to avoid reload issues.

---

#### Flyway for Database Migration

[Flyway](https://www.red-gate.com/products/flyway/community/) is used to manage table creation and test data insertion,
ensuring reliable and reproducible database setup.
Each service, including the monolith, has a dedicated `db/migration` directory containing SQL migration scripts.

* **Reasoning**:
  - Flyway offers a reliable way to version-control schema and seed data.
  - It ensures all developers apply migrations consistently across environments.

* **Tradeoffs**:
  - Migration script versions must be managed carefully.
  - Manual database changes can bypass Flyway. Tooling may be required to reset or reapply migrations.

---

### 2.3. Adoption Strategy
#### Instruction and Documentation
  Provide a step-by-step guide in the README.md explaining how to start, build, and test services using the new workflow. 

#### Incremental Migration of Other Services
  Begin with 2–3 representative services (monolith, user, order) and progressively apply the same structure and tooling (e.g., Flyway, build.sh) to the rest of the services, avoiding big-bang changes.

---
## 3. Prototype

### 3.1. Repository Structure
```
dev-env/
├── README.md                         # Project documentation
├── onboard.sh                        # Script to onboard and start specific services
├── docker-compose.yml               # Docker Compose configuration
├── env_files                              # Environment variable definitions
├── mysql-custom.Dockerfile           # Custom MySQL Dockerfile
├── scripts/
│   └── init.sql                      # Initial SQL setup script
├── monolith/                         # Monolithic Spring Boot application
│   ├── build.gradle, dev.Dockerfile, build.sh, gradlew*
│   ├── src/
│   │   ├── main/java/...             # Application source code
│   │   └── main/resources/
│   │       ├── application-*.properties
│   │       └── db/migration/         # Flyway migration scripts
│   └── build/                        # Compiled classes and test results
├── services/
│   ├── user/                         # Microservice (same structure as monolith)
│   └── order/                        # Microservice (same structure as monolith)
```

---

### 3.2. How to Build and Run

#### 3.2.1. Prerequisites

To run this onboarding tool successfully, ensure the following requirements are met:

1. **Supported Operating Systems**

   * **Linux**  — *Recommended*
   * **Windows (via WSL2 or Linux-based remote environment)**  — *Confirmed to work on WSL2*
   * **macOS**  — *Not yet tested. May work, but not guaranteed*

---

2. **Required Tools**

   | Tool               | Notes                                                         |
   | ------------------ | ------------------------------------------------------------- |
   | **Docker**         | Docker Engine v20+ installed and running                      |
   | **Docker Compose** | Version 2.x or higher (i.e. `docker compose` CLI available)   |
   | **Bash**           | The script assumes a POSIX-compliant shell (e.g. `/bin/bash`) |
   | **Git** | Required when cloning the repository via Git               |

---

3. **Network and Port Availability**

   * An active internet connection is required for initial Docker image pulls.
   * Ensure that commonly used ports (e.g. `8080`, `3306`) are not blocked or in use.

---

4. **Recommended Development Tools**

   * Java IDEs such as **IntelliJ IDEA**, **Eclipse**, or **VS Code**.

---

5. **Minimum Recommended System Resources**

   Running multiple service and database containers may consume significant system resources. 
   Ensure your machine meets the following minimum specifications for a smooth development experience:

   - **CPU**: 2 cores or more
   - **Memory (RAM)**: 8 GB minimum
   - **Storage**: At least 10 GB of available disk space<br><br>

   If your system does not meet these requirements, containers may run slowly, fail to start, or be killed due to resource constraints.

---


#### 3.2.2. Setup Instructions

1. **Clone the Repository**

   At your working directory, clone the dev-env repository and move into the dev-env directory.

      ```bash
      git clone https://github.com/oldneK/dev-env.git
      cd dev-env
      ```

---

2. **Configure Environment Variables (Optional)**

   The default environment variable settings provided in the `env_files/` directory should work for this prototype.
   If you need to change database credentials, server ports, or other service-specific settings, you can modify the corresponding `*.env` files.

   For example:
      ```dotenv
      # env_files/monolith.env
      SPRING_DATASOURCE_URL="jdbc:mysql://db:3306/monolith_db?useSSL=false&allowPublicKeyRetrieval=true&serverTimezone=UTC"
      SPRING_DATASOURCE_USERNAME="monolith_user"
      SPRING_DATASOURCE_PASSWORD="monolith_pass"
      SERVER_PORT="8080"
      ```
      - **SPRING_DATASOURCE_URL**: The JDBC URL used by Spring to connect to the database.
      - **SPRING_DATASOURCE_USERNAME**: The username used to authenticate with the database.
      - **SPRING_DATASOURCE_PASSWORD**: The password used to authenticate with the database.
      - **SERVER_PORT**: The port on which the application will run.<br><br>

      ```dotenv
      # env_files/mysql-db.env
      MYSQL_ROOT_PASSWORD=rootpassword
      MYSQL_DATABASE=dev_db
      MYSQL_USER=user
      MYSQL_PASSWORD=password
      ```
      - **MYSQL_ROOT_PASSWORD**: The root (admin) password for the MySQL server.  
      - **MYSQL_DATABASE**: The name of the database.  
      - **MYSQL_USER**: A non-root MySQL user name.  
      - **MYSQL_PASSWORD**: The password for the MySQL user defined above.  

---

3. **Make the Onboarding Script Executable**

      ```bash
      chmod +x onboard.sh
      ```

---

4. **Start the Development Environment**

   You can selectively launch one or more services using the `onboard.sh` script. This script starts the required Docker containers and builds the service code if needed.
   This prototype includes three services: `monolith`, `user`, and `order`.
   To start a single service, run:
      ```bash
      ./onboard.sh monolith
      ```
   You can also start multiple services at once:
      ```bash
      ./onboard.sh user order
      ```

   The script automatically does the following:
   * Builds the Docker image (if needed)
   * Mounts source code into the container
   * Sets up MySQL and applies Flyway migrations
   * Enables DevTools-based hot reload for rapid iteration<br><br>
   
   It may take a few minutes for containers to finish initializing after the script is complete.
   Once initialization is complete,
   - access monolith at: [http://localhost:8080](http://localhost:8080)  
   - access user service at: [http://localhost:8081](http://localhost:8081)  
   - access order service at: [http://localhost:8082](http://localhost:8082)  

---

#### 3.2.3. Run Builds and Tests

To build and test (JUnit) a service inside its container, use:

```bash
cd <service directory>
./build.sh
```

You can replace `<service directory>` with paths such as `monolith`, `services/user`, `services/order`, etc., relative to the project root.

A unit test coverage report using JaCoCo is generated when running `./build.sh`.
The HTML report will be available at:
`<service directory>/build/reports/jacoco/test/html/index.html`  
You can open this file in your browser to explore coverage per class and method.


---

#### 3.2.4. Database Migrations with Flyway

Each time you run `./onboard.sh`, it starts the relevant containers using Docker Compose. When the application containers start, Flyway will automatically apply the latest database schema and data migrations as part of the service startup process.

Flyway migration scripts are located in each service’s `src/main/resources/db/migration/` directory, and follow the naming convention:

V1\_\_create\_tables.sql  
V2\_\_insert\_initial\_data.sql  

If you add or modify migration files, re-run the onboarding script or restart the affected service container:

```bash
./onboard.sh monolith
```

This ensures the latest schema changes are applied automatically.

---

#### 3.2.5. Stopping the Environment

To stop all containers:

```bash
docker compose --project-name dev-env down
```

---

#### 3.2.6. Troubleshooting
#####  Service Failures
If a service crashes or fails to stay up after running `./onboard.sh`, follow these steps:

1. **Check Logs**

   Use `docker logs` to inspect the error message:

      ```bash
      docker logs -f <service name>
      ```

   Replace `<service name>` with `monolith`, `user`, or `order`.

2. **Inspect Container Status**

   See which containers exited unexpectedly:

      ```bash
      docker ps -a
      ```

   Look for containers with `Exited` status and note the exit code.

3. **Restart the Affected Service**

   If the error was transient (e.g., slow DB startup), try restarting:

      ```bash
      ./onboard.sh <service name>
      ```

---

##### Service fails to start due to build errors
  If the application code contains compilation errors, the service will fail to start. 
  Please review the error messages shown during the build process, fix the issues in the source code, and then rerun the `onboard.sh` script.

---

#### 3.2.7. Tips

* If you modify Java source files on the host, changes are detected and hot-reloaded automatically inside the container (via Spring Boot DevTools).

---

## 4. Measurement & Impact

### 4.1. How would you measure success?

Success will be evaluated based on the **reduction in onboarding time**, **improvements in the stability of local development environments**, and **overall developer experience (DX)**. Key metrics include:

* **Onboarding Time Reduction**  
  Measure the time it takes for new engineers to set up their local environment and begin development (e.g., reduced from an average of 3 hours to 30 minutes).

* **First Commit Time**  
  Track the average time it takes for new joiners to submit their first pull request.

* **Setup Failure Rate**  
  Monitor the number of errors, support requests, or occurrences of "It works on my machine" during environment setup.

---

### 4.2. How would you gather feedback?

Qualitative feedback from engineers will be collected using the following methods:

* **Onboarding Retrospective Survey**  
  Conduct a short survey (e.g., via Google Forms) after onboarding is completed. Sample questions:

  * "What took the most time during setup?"
  * "Did you find `onboard.sh` helpful?"
  * "Was there any missing or unclear information in the documentation?"

* **Team Retrospectives**  
  Discuss local development and onboarding challenges as part of regular sprint retrospectives to identify pain points and opportunities for improvement.

* **GitHub Issues/Discussions**  
  Use GitHub Issues or Discussions to centralize bug reports and suggestions related to `onboard.sh` and local setup scripts. Encourage a culture where developers are welcome to submit improvements via pull requests.

---

## 5. Appendix

### 5.1 References

This section lists external resources and documentation referenced or utilized in this project. Citing reliable sources enhances the credibility and reproducibility of the proposed solution.

* Docker documentation – [https://docs.docker.com](https://docs.docker.com)
* Docker Compose – [https://docs.docker.com/compose/](https://docs.docker.com/compose/)
* Spring Boot DevTools – [https://docs.spring.io/spring-boot/reference/using/devtools.html](https://docs.spring.io/spring-boot/reference/using/devtools.html)
* Flyway documentation – [https://documentation.red-gate.com/fd/](https://documentation.red-gate.com/fd/)
* JaCoCo Code Coverage Library – [https://www.jacoco.org/jacoco/](https://www.jacoco.org/jacoco/)

---

### 5.2 Future Improvements

This section outlines current limitations of the approach and potential enhancements or feature additions to be considered in the future.

#### Proposed Future Enhancements:

* **Service Dependency Graph Visualization**  
  Visualize service dependencies during `onboard.sh` execution to preemptively detect missing services needed for startup.

* **Integration Test Support via Docker Compose**  
  Develop a framework to automatically run integration tests by orchestrating dependent services together through Docker Compose.

* **Mocking and Service Virtualization**  
  Introduce mocking (e.g., using WireMock, Testcontainers) to simulate dependent microservices, enabling isolated development and testing.

* **Onboarding Metrics Dashboard**  
  Collect anonymous metrics on environment setup times and errors per developer to continuously monitor and improve the onboarding process.


