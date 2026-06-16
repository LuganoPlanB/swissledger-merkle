
setup:
	./scripts/install-deps
	./scripts/keygen

build:
	forge build

generate-vectors:
	npm run generate:vectors

test-client:
	npm test

test-solidity:
	forge test

test: test-client test-solidity
