# Build arguments
ARG SOURCE_CODE=.
ARG CI_CONTAINER_VERSION="unknown"

## CPaaS CODE BEGIN ##
FROM registry.redhat.io/ubi8/ubi-minimal AS stage
## CPaaS CODE END ##


## CPaaS CODE BEGIN ##
ENV STAGE_DIR="/tmp/artifacts"
COPY artifacts/trustyai-artifacts.zip /tmp/artifacts/
# Install packages for the install script and extract archives
RUN microdnf --setopt=install_weak_deps=0 --setopt=tsflags=nodocs install -y unzip
RUN unzip /tmp/artifacts/trustyai-artifacts.zip -d /root/
## CPaaS CODE END ##

###############################################################################
FROM registry.redhat.io/ubi8/openjdk-17-runtime:latest as runtime
ENV LANGUAGE='en_US:en'


## CPaaS CODE BEGIN ##
COPY --from=stage /root/explainability-service/target/quarkus-app/lib/ /deployments/lib/
COPY --from=stage /root/explainability-service/target/quarkus-app/*.jar /deployments/
COPY --from=stage /root/explainability-service/target/quarkus-app/app/ /deployments/app/
COPY --from=stage /root/explainability-service/target/quarkus-app/quarkus/ /deployments/quarkus/
## CPaaS CODE END ##

## Build args to be used at this step
ARG CI_CONTAINER_VERSION
ARG USER=185
ENV JAVA_OPTS="-Dquarkus.http.host=0.0.0.0 -Djava.zutil.logging.manager=org.jboss.logmanager.LogManager"
ENV JAVA_APP_JAR="/deployments/quarkus-run.jar"

LABEL com.redhat.component="odh-trustyai-service-container" \
      name="managed-open-data-hub/odh-trustyai-service-rhel8" \
      version="${CI_CONTAINER_VERSION}" \
      git.url="${CI_TRUSTYAI_EXPLAINABILITY_UPSTREAM_URL}" \
      git.commit="${CI_TRUSTYAI_EXPLAINABILITY_UPSTREAM_COMMIT}" \
      summary="odh-trustyai-service" \
      io.openshift.expose-services="" \
      io.k8s.display-name="odh-trustyai-service" \
      maintainer="['managed-open-data-hub@redhat.com']" \
      description="TrustyAI is a service to provide integration fairness and bias tracking to modelmesh-served models" \
      com.redhat.license_terms="https://www.redhat.com/licenses/Red_Hat_Standard_EULA_20191108.pdf"
