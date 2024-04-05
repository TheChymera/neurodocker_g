# We must allow others exactly use our script without modification
# Or its not replicable by others.
#
REGISTRY=docker.io
REPOSITORY=centerforopenneuroscience

IMAGE_NAME=neurodocker_g
IMAGE_TAG=0.0.1

FQDN_IMAGE=${REGISTRY}/${REPOSITORY}/${IMAGE_NAME}:${IMAGE_TAG}

OCI_BINARY?=podman
PACKAGE_NAME=mvmnda

DISTFILE_CACHE_CMD :=

# Default distfile path
DISTFILE_CACHE_PATH?=/var/cache/distfiles

ifneq "$(wildcard $(DISTFILE_CACHE_PATH) )" ""
        DISTFILE_CACHE_CMD =-v $(DISTFILE_CACHE_PATH):/var/cache/distfiles
else
	Leave it undefined if the dir doesn't exist
endif

.PHONY: oci-image-interactive
oci-image-interactive:
	$(OCI_BINARY) run \
	    -it \
	    -f Containerfile_ \
	    /bin/bash

.PHONY: oci-image
oci-image:
	$(OCI_BINARY) build . $(DISTFILE_CACHE_CMD) \
		-f Containerfile \
		-t ${FQDN_IMAGE}

.PHONY: oci-push
oci-push:
	$(OCI_BINARY) push ${FQDN_IMAGE}


.PHONY: clean
clean:
	rm -rf ${SCRATCH_PATH}
