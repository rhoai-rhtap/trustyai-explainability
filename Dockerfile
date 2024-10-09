# Copyright 2023 Red Hat
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

# Build arguments
ARG SOURCE_CODE=.
ARG CI_CONTAINER_VERSION="unknown"

FROM registry.redhat.io/ubi8/ubi-minimal AS stage

# Define a build argument for the PNC list of built files
ARG PNC_FILES_JSON
RUN echo "Files to download: $PNC_FILES_JSON"

# Install packages for the install script and extract archives
RUN microdnf --setopt=install_weak_deps=0 --setopt=tsflags=nodocs install -y unzip jq wget

ENV STAGE_DIR="/tmp/artifacts"
WORKDIR $STAGE_DIR

# Filter the zip files only and unzip them in /root/
RUN echo "$PNC_FILES_JSON" | jq -r '.[] | select(test("\\.zip$"))' | \
    while read url; do wget --no-check-certificate "$url"; done && \
    for file in *.zip; do unzip -d /root/ "$file"; done



###############################################################################
FROM registry.redhat.io/ubi8/openjdk-17-runtime:latest as runtime
ENV LANGUAGE='en_US:en'

## Livebuilder CODE BEGIN ##
# We make four distinct layers so if there are application changes the library layers can be re-used
COPY --from=stage /root/explainability-service/target/quarkus-app/lib/ /deployments/lib/
COPY --from=stage /root/explainability-service/target/quarkus-app/*.jar /deployments/
COPY --from=stage /root/explainability-service/target/quarkus-app/app/ /deployments/app/
COPY --from=stage /root/explainability-service/target/quarkus-app/quarkus/ /deployments/quarkus/


## Build args to be used at this step
ARG CI_CONTAINER_VERSION
ARG USER=185
ENV JAVA_OPTS="-Dquarkus.http.host=0.0.0.0 -Djava.zutil.logging.manager=org.jboss.logmanager.LogManager"
ENV JAVA_APP_JAR="/deployments/quarkus-run.jar"

LABEL com.redhat.component="odh-trustyai-service" \
      name="managed-open-data-hub/odh-trustyai-service-rhel8" \
      version="${CI_CONTAINER_VERSION}" \
      summary="odh-trustyai-service" \
      io.openshift.expose-services="" \
      io.k8s.display-name="odh-trustyai-service" \
      maintainer="['managed-open-data-hub@redhat.com']" \
      description="TrustyAI is a service to provide integration fairness and bias tracking to modelmesh-served models" \
      com.redhat.license_terms="https://www.redhat.com/licenses/Red_Hat_Standard_EULA_20191108.pdf"
