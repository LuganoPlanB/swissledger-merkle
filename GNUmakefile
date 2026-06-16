
setup:
	./scripts/install-deps
	./scripts/keygen

build:
	forge build

generate-vectors:
	npm run generate:vectors

test-parity: generate-vectors
	forge test --match-path test/generated/GeneratedMerkleParity.t.sol

test-client:
	npm test

test-solidity:
	forge test

test: test-client test-solidity
