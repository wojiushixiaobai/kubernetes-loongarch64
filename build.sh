#!/bin/bash
#

set -e

KUBERNETES_VERSION=$1

if [ -n "${KUBERNETES_VERSION}" ]; then
    echo "Kubernetes version: ${KUBERNETES_VERSION}"
else
    echo "Kubernetes version is not set"
    echo "Usage: $0 <kubernetes-version>"
    exit 1
fi

for command in wget tar git docker jq make rsync; do
    if ! command -v ${command} >/dev/null 2>&1; then
        echo "Command ${command} is not found"
        exit 1
    fi
done

# http://ftp.loongnix.cn/toolchain/golang/go-1.20/abi1.0/go1.20.6.linux-loong64.tar.gz
GOVERSION=1.20.6
GO_MAJOR_VERSION=1.20

if [ -d "/opt/golang/${GOVERSION}/go" ]; then
    echo "Golang ${GOVERSION} is already installed"
else
    echo "Installing Golang ${GOVERSION}"
    mkdir -p /opt/golang
    wget -qO /opt/golang/go${GOVERSION}.linux-loong64.tar.gz http://ftp.loongnix.cn/toolchain/golang/go-${GO_MAJOR_VERSION}/abi1.0/go${GOVERSION}.linux-loong64.tar.gz
    tar xf /opt/golang/go${GOVERSION}.linux-loong64.tar.gz -C /opt/golang
fi
export PATH=/opt/golang/1.20.6/go/bin:$PATH

mkdir -p dist/

TMPDIR=$(mktemp -d)

if [ ! -d "${TMPDIR}" ]; then
    echo "Failed to create temporary directory"
    exit 1
fi

git clone -b ${KUBERNETES_VERSION} --depth 1 https://github.com/kubernetes/kubernetes ${TMPDIR}/kubernetes

cp -R patch ${TMPDIR}/patch

# build images
BASEIMAGE=registry.k8s.io/build-image/debian-base-loong64:bookworm-v1.0.0
DEBIAN_BASE_VERSION=${BASEIMAGE#*:}

KUBE_CROSS_IMAGE=registry.k8s.io/build-image/kube-cross
KUBE_CROSS_VERSION=$(cat ${TMPDIR}/kubernetes/build/build-image/cross/VERSION)
CROSSIMAGE=${KUBE_CROSS_IMAGE}:${KUBE_CROSS_VERSION}

GO_RUNNER_IMAGE=registry.k8s.io/build-image/go-runner
GO_RUNNER_VERSION=$(cat ${TMPDIR}/kubernetes/build/common.sh | grep go_runner_version= | sed 's/.*=//')
RUNNERIMAGE=${GO_RUNNER_IMAGE}:${GO_RUNNER_VERSION}

SETCAP_IMAGE=registry.k8s.io/build-image/setcap
SETCAP_VERSION=${DEBIAN_BASE_VERSION}
SETCAPIMAGE=${SETCAP_IMAGE}:${SETCAP_VERSION}

DISTROLESS_IPTABLES_IMAGE=registry.k8s.io/build-image/distroless-iptables
DISTROLESS_IPTABLES_VERSION=$(cat ${TMPDIR}/kubernetes/build/common.sh | grep distroless_iptables_version= | sed 's/.*=//')
IPTABLEIMAGE=${DISTROLESS_IPTABLES_IMAGE}:${DISTROLESS_IPTABLES_VERSION}

echo "Checking images ...."
echo "Checking image from $BASEIMAGE"
if ! docker images --format "{{.Repository}}:{{.Tag}}" | grep $BASEIMAGE; then
    # TAG=bookworm-v1.0.0
    TAG=${DEBIAN_BASE_VERSION} make -C images/build/debian-base
fi

echo "Checking image from $CROSSIMAGE"
if ! docker images --format "{{.Repository}}:{{.Tag}}" | grep $CROSSIMAGE; then
    # TAG=v1.27.0-go1.20.7-bullseye.0 GO_VERSION=1.20.6
    TAG=${KUBE_CROSS_VERSION} GO_VERSION=${GOVERSION} make -C images/build/cross
fi

echo "Checking image from $RUNNERIMAGE"
if ! docker images --format "{{.Repository}}:{{.Tag}}" | grep $RUNNERIMAGE; then
    # TAG=v2.3.1-go1.20.7-bullseye.0 DEBIAN_BASE_VERSION=bookworm-v1.0.0 GO_VERSION=1.20.6 GO_MAJOR_VERSION=1.20
    TAG=${GO_RUNNER_VERSION} DEBIAN_BASE_VERSION=${DEBIAN_BASE_VERSION} GO_VERSION=${GOVERSION} GO_MAJOR_VERSION=${GO_MAJOR_VERSION} make -C images/build/go-runner
fi

echo "Checking image from $SETCAPIMAGE"
if ! docker images --format "{{.Repository}}:{{.Tag}}" | grep $SETCAPIMAGE; then
    # TAG=v1.0.0-bookworm.0 DEBIAN_BASE_VERSION=bookworm-v1.0.0
    TAG=${SETCAP_VERSION} DEBIAN_BASE_VERSION=${DEBIAN_BASE_VERSION} make -C images/build/setcap
fi

echo "Checking image from $IPTABLEIMAGE"
if ! docker images --format "{{.Repository}}:{{.Tag}}" | grep $IPTABLEIMAGE; then
    # TAG=v0.2.7 GORUNNER_VERSION=v2.3.1-go1.20.7-bullseye.0
    TAG=${DISTROLESS_IPTABLES_VERSION} GORUNNER_VERSION=${GO_RUNNER_VERSION} make -C images/build/distroless-iptables
fi

pushd ${TMPDIR}/kubernetes || exit 1

echo "${GOVERSION}" > .go-version
# fix go.mod, github.com/cilium/ebpf v0.11.0 support loong64
sed -i 's@github.com/cilium/ebpf v0.9.1@github.com/cilium/ebpf v0.11.0@g' go.mod
# loong64 not support race
sed -i 's@KUBE_RACE=${KUBE_RACE-"-race"}@KUBE_RACE=""@g' hack/make-rules/test.sh

find ../patch -type f -name "*.patch" | sort | while read -r patch; do
    echo "Applying patch: ${patch}"
    git apply "${patch}"
done

./hack/update-vendor.sh

# fix runc
sed -i 's@|| s390x@|| s390x || loong64@g' vendor/github.com/opencontainers/runc/libcontainer/system/syscall_linux_64.go
sed -i 's@riscv64 s390x@riscv64 s390x loong64@g' vendor/github.com/opencontainers/runc/libcontainer/system/syscall_linux_64.go

KUBE_BUILD_PLATFORMS=linux/loong64 KUBE_BUILD_PULL_LATEST_IMAGES=no make quick-release

ls -al _output/release-tars/

popd

mv -f ${TMPDIR}/kubernetes/_output/release-tars dist/${KUBERNETES_VERSION}

# clean images
docker rm -f $(docker ps -a -q) || true
docker images --format "{{.Repository}}:{{.Tag}}" | grep registry.k8s.io/build-image | xargs docker rmi {} || true
docker image prune -f

rm -rf ${TMPDIR?}
rm -rf /tmp/update-vendor.*
# rm -rf /tmp/tmp.*