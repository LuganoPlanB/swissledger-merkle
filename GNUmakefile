FORGE ?= ./bin/swissledger-forge
CAST  ?= ./bin/swissledger-cast
ANVIL ?= ./bin/swissledger-anvil

setup:
	./scripts/install-deps
	./scripts/keygen

generate-build-info:
	npm run generate:build-info

build: generate-build-info
	$(FORGE) build

generate-vectors:
	npm run generate:vectors

test-all: build generate-vectors test-client test-solidity test-parity test-smoke

test-parity: generate-build-info generate-vectors
	$(FORGE) test --match-path test/generated/GeneratedMerkleParity.t.sol

test-smoke: generate-build-info
	./scripts/e2e-smoke

test-client:
	npm test

test-solidity: generate-build-info
	$(FORGE) test

test: test-all
