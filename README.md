# swissledger-up

This repository builds a Solidity Merkle verifier and its local client around
`@ericnordelo/strk-merkle-tree@1.0.1`.

The canonical Merkle rules are documented in
[docs/strk-merkle-tree-parity.md](./docs/strk-merkle-tree-parity.md).
Everything in this repo is expected to match `StandardMerkleTree` from that
package.

## Setup

```bash
make setup
npm ci
```

## Review Commands

Generate canonical vectors:

```bash
make generate-vectors
```

Run the Node client tests:

```bash
make test-client
```

Run the Solidity tests:

```bash
make test-solidity
```

Regenerate vectors and prove Solidity parity from the generated fixtures:

```bash
make test-parity
```

Run the local Anvil smoke flow:

```bash
make test-smoke
```

Run the full local test surface:

```bash
make test
```
