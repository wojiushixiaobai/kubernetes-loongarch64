# Copyright 2017 The Kubernetes Authors.
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

all: build

REGISTRY ?= registry.k8s.io/build-image
IMAGE ?= $(REGISTRY)/debian-base
BUILD_IMAGE ?= debian-build

TAG ?= bookworm-v1.0.0
CONFIG ?= buster

TAR_FILE ?= rootfs.tar
ARCH ?= loong64

# This option is for running docker manifest command
export DOCKER_CLI_EXPERIMENTAL := enabled

ifeq ($(ARCH),loong64)
	BASEIMAGE?=debian:$(CONFIG)-slim
endif

build: clean
	# Fix possible issues with the local umask
	umask 0022

	docker buildx build \
		--load \
		--platform linux/$(ARCH) \
		--build-arg BASEIMAGE=$(BASEIMAGE) \
		--build-arg ARCH=$(ARCH) \
		-t $(BUILD_IMAGE) \
		-f $(CONFIG)/Dockerfile.build \
		$(CONFIG)
	docker create --name $(BUILD_IMAGE) $(BUILD_IMAGE)
	docker export $(BUILD_IMAGE) > $(CONFIG)/$(TAR_FILE)
	docker buildx build \
		--load \
		--platform linux/$(ARCH) \
		-t $(IMAGE)-$(ARCH):$(TAG) \
		$(CONFIG)
	rm $(CONFIG)/rootfs.tar

push: build
	docker push $(IMAGE)-$(ARCH):$(TAG)

clean:
	docker rmi -f $(IMAGE)-$(ARCH):$(TAG) || true
	docker rmi -f $(BUILD_IMAGE)   || true
	docker rm  -f $(BUILD_IMAGE)   || true