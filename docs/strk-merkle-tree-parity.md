# strk-merkle-tree parity

`@ericnordelo/strk-merkle-tree@1.0.1` is the canonical Merkle blueprint for this repository.

This repository does not define an alternative tree format.
The Solidity verifier, local client, fixtures, and end-to-end tests must match
the behavior of `StandardMerkleTree` from that package.

## Required semantics

- Build trees with `StandardMerkleTree.of(values, leafEncoding)`.
- Use the default options unless a test explicitly proves a different mode.
- Leaves are sorted by hash by default.
- The tree shape is a complete binary tree.
- Standard leaf hashing is `standardLeafHash(types, value)`.
- Standard internal node hashing is `standardNodeHash(left, right)`.
- Standard node hashing sorts the pair, then calls `hash.computeHashOnElements(sortedPair)`.
- Standard leaf hashing is `hash.computePedersenHash(0, hash.computeHashOnElements(serialize(types, value)))`.
- Proofs are generated with `tree.getProof(index)` and verified against the same semantics.
- Dumps are produced by `tree.dump()` and reloaded by `StandardMerkleTree.load(...)`.

## Scope

The existing [OpenZeppelin Cairo Merkle note](./openzeppelin_cairo_2_merkle-tree.txt)
is background only.
The executable source of truth for this blueprint is the JavaScript library above
and the fixture vectors generated from it in this repository.
