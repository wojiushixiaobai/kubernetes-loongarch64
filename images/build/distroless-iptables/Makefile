# Copyright 2022 The Kubernetes Authors.
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

.PHONY:	build

REGISTRY ?= registry.k8s.io/build-image
IMAGE=$(REGISTRY)/distroless-iptables

TAG ?= v0.2.7
CONFIG ?= distroless
BASEIMAGE ?= debian:buster-slim
GORUNNER_VERSION ?= v2.3.1-go1.20.11-bullseye.0

ARCH?=loong64

BASE_REGISTRY?=registry.k8s.io/build-image

GORUNNERIMAGE?=$(BASE_REGISTRY)/go-runner:$(GORUNNER_VERSION)

ifneq ($(ARCH), amd64)
	SKIP_WRAPPER_CHECK=--no-sanity-check
endif

# This option is for running docker manifest command
export DOCKER_CLI_EXPERIMENTAL := enabled

SUDO=$(if $(filter 0,$(shell id -u)),,sudo)

build:
	# Fix possible issues with the local umask
	umask 0022

	docker buildx build \
		--load \
		--platform linux/$(ARCH) \
		-t $(IMAGE):$(TAG) \
		--build-arg=BASEIMAGE=$(BASEIMAGE) \
		--build-arg=GORUNNERIMAGE=$(GORUNNERIMAGE) \
		--build-arg=SKIP_WRAPPER_CHECK=$(SKIP_WRAPPER_CHECK) \
		$(CONFIG)