.DEFAULT_GOAL := help

BUNDLE_NAME=whalegap
BUNDLE=whalegap:v0.1.0
CREDS=kubeconfig
APP_NAME=whalegap

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
	porter install $(APP_NAME) --cred $(CREDS)

.PHONY: upgrade
upgrade: ## Upgrade bundle and change the message
	porter upgrade $(APP_NAME) --cred $(CREDS) --param="msg=Hello DevoxxFR!"

.PHONY: list
list: ## Display installed application
	porter list

.PHONY: uninstall
uninstall: ## Uninstall application bundle
	porter uninstall $(APP_NAME) --cred $(CREDS)

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