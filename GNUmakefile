
setup:
	./scripts/install-deps
	./scripts/keygen

generate-build-info:
	npm run generate:build-info

build: generate-build-info
	forge build

generate-vectors:
	npm run generate:vectors

test-all: build generate-vectors test-client test-solidity test-parity test-smoke

test-parity: generate-build-info generate-vectors
	forge test --match-path test/generated/GeneratedMerkleParity.t.sol

test-smoke: generate-build-info
	./scripts/e2e-smoke

test-client:
	npm test

test-solidity: generate-build-info
	forge test

test: test-all
