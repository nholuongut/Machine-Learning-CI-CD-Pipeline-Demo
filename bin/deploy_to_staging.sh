#!/usr/bin/env bash

set -e

source ./bin/common.sh
exit_if_directory_not_specified_as_first_argument $1
exit_if_not_ci

DEPLOYMENT_SOURCE="${BUCKET}/nlp_sentiment/build"
FRAMEWORK="SCIKIT_LEARN"
latest_version_plus_one=$(get_next_version_name_for ${MODEL_NAME})

echo "[INFO] Deploying model to GCP ML Engine..."
model_status_code=$(gcloud beta ml-engine models list | grep -c ${MODEL_NAME} || true) # 1 if model exists, 0 otherwise
if [[ ${model_status_code} == 0 ]]; then
    echo "[INFO] Creating model resource (i.e. a container for all versions of this model)" 
    gcloud beta ml-engine models create ${MODEL_NAME} --regions ${REGION}
fi

echo "[INFO] Creating next version (${latest_version_plus_one}) for model ${MODEL_NAME}"
gcloud beta ml-engine versions create "${latest_version_plus_one}" \
    --model $MODEL_NAME --origin $DEPLOYMENT_SOURCE \
    --runtime-version=1.5 --framework $FRAMEWORK \
    --python-version=3.5

echo "[INFO] Describe model versions"
gcloud beta ml-engine versions describe $latest_version_plus_one \
    --model $MODEL_NAME

./bin/smoke_test.sh ${latest_version_plus_one}
