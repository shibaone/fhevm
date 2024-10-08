#!/usr/bin/make -f

include .env

# Variables
BINDIR ?= $(GOPATH)/bin
BUILDDIR ?= $(CURDIR)/build
SUDO := $(shell which sudo)
OS := $(shell uname -s)
KMS_DEV_VERSION ?= v0.8.1-rc4

export GO111MODULE = on

ifeq ($(OS),Linux)
    IS_LINUX := true
else
    IS_LINUX := false
endif


# Check the OS
check_os:
	@echo "Operating System: $(OS)"
	@if [ "$(IS_LINUX)" = "true" ]; then \
	    echo "This is a Linux system."; \
	else \
	    echo "This is not a Linux system."; \
	fi

# Default target executed when no arguments are given to make.
default_target: all
.PHONY: default_target

# Generate FHE keys for the registry dev image
generate-fhe-keys-registry-dev-image:
ifeq ($(KEY_GEN),false)
	@echo "KEY_GEN is false, executing corresponding commands..."
	@bash ./scripts/copy_fhe_keys.sh $(KMS_DEV_VERSION) $(PWD)/network-fhe-keys $(PWD)/kms-fhe-keys
else ifeq ($(KEY_GEN),true)
	@echo "KEY_GEN is true, executing corresponding commands..."
	@bash ./scripts/prepare_volumes_from_kms_core.sh $(KMS_DEV_VERSION) $(PWD)/network-fhe-keys $(PWD)/kms-fhe-keys
else
	@echo "KEY_GEN is set to an unrecognized value: $(KEY_GEN)"
endif

# Run the full Docker setup
run-full:
	$(MAKE) generate-fhe-keys-registry-dev-image
ifeq ($(KEY_GEN),false)
	@echo "KEY_GEN is false, executing corresponding commands..."
	@docker compose -f docker-compose/docker-compose-full.yml up --detach
else ifeq ($(KEY_GEN),true)
	@echo "KEY_GEN is true, mounting FHE keys into kms-core..."
	@docker compose -f docker-compose/docker-compose-full.yml -f docker-compose/docker-compose-full.override.yml up --detach
else
	@echo "KEY_GEN is set to an unrecognized value: $(KEY_GEN)"
endif
	@echo 'Sleeping for 5 seconds to let the Docker services start...'
	sleep 5

# Stop the full Docker setup
stop-full:
	@docker compose -f docker-compose/docker-compose-full.yml down

# Install npm packages for the repo
install-packages:
	@npm i
	@if [ "$(IS_LINUX)" = "true" ]; then \
	    npm i solidity-comments-linux-x64-gnu; \
	fi

# Prepare for e2e testing
prepare-e2e-test:
	$(MAKE) install-packages
	@sleep 5
	@./scripts/fund_test_addresses_docker.sh
	@cp .env.example .env
	@./setup-local-fhevm.sh

# Clean the build and keys
clean:
	$(MAKE) stop-full
	rm -rf $(BUILDDIR)/
	rm -rf network-fhe-keys
	rm -rf kms-fhe-keys
	rm -rf res

# Print environment info
print-info:
	@echo 'KMS_DEV_VERSION: $(KMS_DEV_VERSION)'
	@bash scripts/get_repository_info.sh fhevm $(CURDIR)
