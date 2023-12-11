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

.PHONY:	build

REGISTRY ?= registry.k8s.io/build-image
IMAGE = $(REGISTRY)/go-runner
APP_VERSION = $(shell cat VERSION)
GO_MAJOR_VERSION ?= 1.20
GO_VERSION ?= 1.20.6
OS_CODENAME ?= buster

DEBIAN_BASE_VERSION ?= bookworm-v1.0.0

ARCH ?= loong64

BASE_REGISTRY?=registry.k8s.io/build-image
BASEIMAGE?=$(BASE_REGISTRY)/debian-base-$(ARCH):$(DEBIAN_BASE_VERSION)
BUILDER_IMAGE ?= golang:$(GO_VERSION)-$(OS_CODENAME)

TAG ?= $(APP_VERSION)-go1.20.11-bullseye.0

BUILD_ARGS = --build-arg=BUILDER_IMAGE=$(BUILDER_IMAGE) \
             --build-arg=DISTROLESS_IMAGE=$(BASEIMAGE)

build:
	# Fix possible issues with the local umask
	umask 0022

	docker buildx build \
		--load \
		--progress plain \
		--platform linux/$(ARCH) \
		--tag $(IMAGE):$(TAG) \
		$(BUILD_ARGS) \
		.