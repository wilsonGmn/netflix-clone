#!/bin/bash

# Define the container ID or name
CONTAINER_ID="aaec47b22e1b"

# Define the source directory containing plugin files
SOURCE_DIR="./plugins/"

# Define the destination directory in the Jenkins container
DEST_DIR="/var/jenkins_home/plugins/"

# List of plugin files to copy
FILES=(
    "workflow-job.hpi"
    "workflow-multibranch.hpi"
    "cloudbees-folder.hpi"
    "pipeline-groovy-lib.hpi"
    "config-file-provider.hpi"
    "pipeline.hpi"
    "blueocean-pipeline-api-impl.hpi"
    "blueocean-pipeline-scm-api.hpi"
    "branch-api.hpi"
    "pipeline-rest-api.hpi"
    "prometheus.hpi"
)

# Copy each file to the Jenkins container
for FILE in "${FILES[@]}"; do
    if [ -f "${SOURCE_DIR}${FILE}" ]; then
        echo "Copying ${FILE} to the Jenkins container..."
        docker cp "${SOURCE_DIR}${FILE}" "${CONTAINER_ID}:${DEST_DIR}"
    else
        echo "File ${FILE} does not exist in the source directory."
    fi
done

echo "Plugins copied to Jenkins container."

# Optionally restart Jenkins container (uncomment the line below if needed)
# docker restart ${CONTAINER_ID}
