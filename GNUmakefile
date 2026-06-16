
setup:
	./scripts/install-deps
	./scripts/keygen

build:
	forge build

generate-vectors:
	npm run generate:vectors

test-all: build generate-vectors test-client test-solidity test-parity test-smoke

test-parity: generate-vectors
	forge test --match-path test/generated/GeneratedMerkleParity.t.sol

test-smoke:
	./scripts/e2e-smoke

test-client:
	npm test

test-solidity:
	forge test

test: test-all
