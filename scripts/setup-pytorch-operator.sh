#!/bin/bash

# Copyright 2018 The Kubernetes Authors.
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

# This shell script is used to build a cluster and create a namespace from our
# argo workflow


set -o errexit
set -o nounset
set -o pipefail

CLUSTER_NAME="${CLUSTER_NAME}"
REGION="${AWS_REGION:-us-west-2}"
REGISTRY="${ECR_REGISTRY:-809251082950.dkr.ecr.us-west-2.amazonaws.com}"
VERSION="${PULL_BASE_SHA}"
GO_DIR=${GOPATH}/src/github.com/${REPO_OWNER}/${REPO_NAME}

echo "Configuring kubeconfig.."
aws eks update-kubeconfig --region=${REGION} --name=${CLUSTER_NAME}

echo "Update PyTorch operator manifest with new name and tag"
#TODO(Jeffwan@): If there's a way to specify context, then we don't need to enter manifests folder
cd manifests/overlays/standalone
kustomize edit set image gcr.io/kubeflow-images-public/pytorch-operator=${REGISTRY}/${REPO_NAME}:${VERSION}

echo "Installing PyTorch operator manifests"
kustomize build . | kubectl apply -f -

TIMEOUT=30
until kubectl get pods -n kubeflow | grep pytorch-operator | grep 1/1 || [[ $TIMEOUT -eq 1 ]]; do
  sleep 10
  TIMEOUT=$(( TIMEOUT - 1 ))
done
