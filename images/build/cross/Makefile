# Copyright 2020 The Kubernetes Authors.
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

# set default shell
SHELL=/bin/bash -o pipefail

IMGNAME = kube-cross

# Represents the targeted Kubernetes version at the time the images
# are to be created e.g., 'v1.100.0'
#
# Note: There is no need to increment the patch version of this variable.
#       The reason for the inclusion of the patch version here is to satisfy
#       a SemVer regex on the IMAGE_VERSION.
#
# Example:
# - v1.100.0-go1.17-bullseye.0 satisfies SemVer regex, while:
# - v1.100-go1.17-bullseye.0 does not
REGISTRY ?= registry.k8s.io/build-image

GO_VERSION ?= 1.20.6
GO_MAJOR_VERSION ?= 1.20
OS_CODENAME ?= buster
REVISION ?= 0
TYPE ?= default

# Build args
BASEIMAGE ?= golang:$(GO_VERSION)-$(OS_CODENAME)
PROTOBUF_VERSION ?= 3.21.12

IMAGE = $(REGISTRY)/$(IMGNAME)
TAG ?= v1.28.0-go1.20.11-bullseye.0

# Ensure support for 'docker buildx' and 'docker manifest' commands
export DOCKER_CLI_EXPERIMENTAL=enabled

# TODO: Support multi-arch kube-cross images for linux/arm
#       Currently some of the components references in the Dockerfile are
#       not supported in specific architectures
PLATFORMS ?= linux/loong64

# for legacy images only build linux/loong64
ifeq ($(TYPE), legacy)
  PLATFORMS = linux/loong64
endif

ARCHS = $(patsubst linux/%,%,$(PLATFORMS))

all: container

check-env:
ifndef REGISTRY
	$(error REGISTRY is undefined, please set to registry you want to push)
endif

# build with buildx
# https://github.com/docker/buildx/issues/59
.PHONY: container
container: check-env
	echo "Building $(IMGNAME) for the following platforms: $(PLATFORMS)"
	@for platform in $(PLATFORMS); do \
		echo "Starting build for $${platform} platform"; \
		docker buildx build \
			--load \
			--progress plain \
			--platform $${platform} \
			--tag $(IMAGE):$(TAG) \
			--build-arg=BASEIMAGE=$(BASEIMAGE) \
			--build-arg=PROTOBUF_VERSION=$(PROTOBUF_VERSION) \
			--build-arg=ETCD_VERSION=$(ETCD_VERSION) \
			--file $(TYPE)/Dockerfile \
			.; \
	done