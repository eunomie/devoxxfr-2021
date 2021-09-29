.DEFAULT_GOAL := help

REGISTRY_VOLUME=local-registry

##@ Setup

.PHONY: setup-registry-volume
setup-registry-volume:
	docker volume create $(REGISTRY_VOLUME) || true

.PHONY: setup-registry
setup-registry: setup-registry-volume ## Setup local registry
	docker run -d --name registry --rm -v $(REGISTRY_VOLUME):/var/lib/registry -p 5000:5000 registry:2.7

.PHONY: prepare-demo
prepare-demo: setup-registry ## Setup everything to start the demo
	docker pull bitnami/wordpress:5.8.1-debian-10-r14
	docker pull bitnami/mariadb:10.5.12-debian-10-r32
	docker pull carolynvs/whalesayd@sha256:8b92b7269f59e3ed824e811a1ff1ee64f0d44c0218efefada57a4bebc2d7ef6f
	make -C wordpress build publish
	make -C airgap build publish extract

##@ Cleanup

.PHONY: stop-registry
stop-registry:
	docker stop registry

.PHONY: cleanup
cleanup: cleanup-delete cleanup-registry ## Cleanup everything

.PHONY: cleanup-delete ## Delete applications
cleanup-delete:
	make -C wordpress cleanup
	make -C airgap cleanup
	make -C wordpress cleanup-credentials

.PHONY: cleanup-registry
cleanup-registry: stop-registry ## Stop registry and delete volume
	docker volume rm $(REGISTRY_VOLUME)

.PHONY: help
help:
	@awk 'BEGIN {FS = ":.*##"; printf "\nUsage:\n  make \033[36m\033[0m\n"} /^[a-zA-Z_-]+:.*?##/ { printf "  \033[36m%-17s\033[0m %s\n", $$1, $$2 } /^##@/ { printf "\n\033[1m%s\033[0m\n", substr($$0, 5) } ' $(MAKEFILE_LIST)