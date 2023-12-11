# Copyright 2021 The Kubernetes Authors.
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
IMAGE=$(REGISTRY)/setcap

TAG ?= bookworm-v1.0.0
DEBIAN_BASE_VERSION ?= bookworm-v1.0.0

ARCH ?= loong64

BASE_REGISTRY?=registry.k8s.io/build-image
BASEIMAGE?=$(BASE_REGISTRY)/debian-base-$(ARCH):$(DEBIAN_BASE_VERSION)

# This option is for running docker manifest command
export DOCKER_CLI_EXPERIMENTAL := enabled

build:
	# Fix possible issues with the local umask
	umask 0022

	docker buildx build \
		--load \
		--platform linux/$(ARCH) \
		-t $(IMAGE):$(TAG) \
		--build-arg=BASEIMAGE=$(BASEIMAGE) \
		.