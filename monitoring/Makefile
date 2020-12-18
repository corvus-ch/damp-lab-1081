MAKEFLAGS += --warn-undefined-variables
SHELL := bash
.SHELLFLAGS := -eu -o pipefail -c
.DEFAULT_GOAL := help
.DELETE_ON_ERROR:
.SUFFIXES:

CURRENT_DIR := $(dir $(abspath $(lastword $(MAKEFILE_LIST))))

DOCKER_CMD  := docker
DOCKER_ARGS := --rm -v "$(CURRENT_DIR):$(CURRENT_DIR)" --workdir "$(CURRENT_DIR)" quay.io/coreos/jsonnet-ci

manifests: monitoring.jsonnet vendor ## Build the monitoring manifests
	rm -rf "$@"
	mkdir -p "$@/setup"
	$(DOCKER_CMD) run $(DOCKER_ARGS) sh -c "jsonnet -J vendor -m $@ '$<' | xargs -I{} sh -c 'cat {} | gojsontoyaml > {}.yaml; rm -f {}' -- {}"

vendor: jsonnetfile.json jsonnetfile.lock.json ## Install the Jsonnet depencendies
	$(DOCKER_CMD) run $(DOCKER_ARGS) jb install

jsonnetfile.lock.json: jsonnetfile.json ## Update the Jsonnet dependencies
	$(DOCKER_CMD) run $(DOCKER_ARGS) jb update

.PHONY: clean
clean: ## Deletes all build artefacts
	rm -rf manifests vendor

.PHONY: help
help: ## Show this help
	@egrep -h '\s##\s' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-20s\033[0m %s\n", $$1, $$2}'
