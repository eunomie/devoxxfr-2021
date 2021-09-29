.DEFAULT_GOAL := help

BUNDLE_NAME=devoxxfr
BUNDLE_VERSION=2021.9.75
BUNDLE=$(BUNDLE_NAME):v$(BUNDLE_VERSION)
APP_NAME=devoxxfrdemo
NAMESPACE=devoxxfr
CREDS=kubeconfig

##@ Credentials

.PHONY: setup-credentials
setup-credentials: ## Generate kube credentials
	porter credentials generate $(CREDS)

.PHONY: list-credentials
list-credentials: ## Display existing credential sets
	porter credentials list

##@ Porter

.PHONY: explain
explain: ## Explain bundle
	porter explain

.PHONY: build
build: ## Build bundle
	porter build

.PHONY: publish
publish: ## Publish bundle to a registry
	porter publish --insecure-registry --registry 127.0.0.1:5000

.PHONY: inspect
inspect: ## Inspect bundle from a registry
	porter inspect --insecure-registry --reference 127.0.0.1:5000/$(BUNDLE)

.PHONY: install
install: ## Install bundle on docker desktop's kubernetes
	porter install $(APP_NAME) --cred $(CREDS) --param="context=docker-desktop" --param="namespace=$(NAMESPACE)"

uninstall: ## Uninstall application bundle
	porter uninstall $(APP_NAME) --cred $(CREDS)

list: ## Display installed application
	porter list

.PHONY: list-namespaces
list-namespaces: ## List kubernetes namespaces
	kubectl get namespaces

.PHONY: list-all-namespace
list-all-namespace: ## List all resourrces in kubernetes namespace
	kubectl get all --namespace $(NAMESPACE)
.PHONY: extract
extract: archive uncompress ## Extract content of the bundle

.PHONY: archive
archive:
	@mkdir -p archive
	porter bundle archive archive/$(BUNDLE_NAME).tgz --reference 127.0.0.1:5000/$(BUNDLE)

uncompress:
	@(\
		cd archive; \
		tar xf $(BUNDLE_NAME).tgz; \
		rm -f $(BUNDLE_NAME).tgz \
	)

##@ Cleanup

.PHONY: cleanup
cleanup: cleanup-delete cleanup-archive cleanup-cnab ## Cleanup everything

.PHONY: cleanup-delete ## Delete application
cleanup-delete:
	porter uninstall $(APP_NAME) --cred $(CREDS) --delete || true

.PHONY: cleanup-credentials
cleanup-credentials: ## Delete credential set
	porter credentials delete $(CREDS) || true

.PHONY: cleanup-archive
cleanup-archive: ## Delete archive
	rm -Rf archive

.PHONY: cleanup-cnab
cleanup-cnab:
	rm -Rf .cnab

.PHONY: help
help:
	@awk 'BEGIN {FS = ":.*##"; printf "\nUsage:\n  make \033[36m\033[0m\n"} /^[a-zA-Z_-]+:.*?##/ { printf "  \033[36m%-17s\033[0m %s\n", $$1, $$2 } /^##@/ { printf "\n\033[1m%s\033[0m\n", substr($$0, 5) } ' $(MAKEFILE_LIST)