<!--
SPDX-FileCopyrightText: 2026 PlanB foundation

SPDX-License-Identifier: AGPL-3.0-or-later
-->

# Swissledger Merkle

This repository builds a Merkle verifier and its local client.

The canonical Merkle rules are documented in
[docs/strk-merkle-tree-parity.md](./docs/strk-merkle-tree-parity.md).
Everything in this repo is expected to match `StandardMerkleTree` from that
package.

## Active Root Model

This contract keeps only one Merkle root on-chain:

- `activeRoot` is the latest valid state
- `owner` manages the list of root updaters
- `getRootUpdaters()` returns the currently allowed updater addresses
- `setActiveRoot(newRoot)` replaces the previous root
- `contains(...)` verifies a raw hash for trees built with `["felt252"]`
- `containsLeafHash(...)` verifies a canonical leaf hash directly
- `containsMany(...)` verifies only against `activeRoot`

This means:

- when you add hashes, rebuild the full tree off-chain and call `setActiveRoot`
- when you revoke hashes, rebuild the full tree without those hashes and call `setActiveRoot`
- old proofs stop working as soon as a new root replaces the previous one
- on-chain storage does not grow with the number of updates; only the current root is stored

Simple example:

1. Build a tree from `H1, H2` and set that root.
2. Later rebuild from `H1, H2, H3` and set the new root.
3. Later rebuild from `H1, H3` to revoke `H2` and set the new root.

Only the last root is valid.

Root rotation is not restricted to a single key. The contract keeps an
owner-managed allowlist of updater addresses. Any allowed updater may publish
the next `activeRoot`, and the owner can add or remove updater addresses as
operational keys change.

For hash-only expiration sets, keep insertion and expiry data off-chain and build
the tree from raw hashes:

```json
{
  "leafEncoding": ["felt252"],
  "values": [["0xHASH_1"], ["0xHASH_2"]]
}
```

Then clients can verify directly by raw hash:

```text
contains(hash, proof) -> bool
```

Use `containsLeafHash(leafHash, proof)` only when the caller already has the
canonical Merkle leaf hash.

## Versioning And Releases

This repository now uses conventional-commit semantic versioning on the main
release branch.

- pushes to `master` trigger the release workflow
- this checkout also accepts `main`, because the current default branch is `main`
- `semantic-release` computes the next SemVer version from conventional commits
- `CHANGELOG.md` is updated automatically
- a GitHub release and Git tag are created automatically

The Solidity build also embeds the current project version:

- `scripts/generate-build-info.mjs` writes `src/generated/BuildInfo.sol`
- Forge targets regenerate that file before compiling
- `MerkleRootRegistry.version()` returns the embedded version string

Clients can call:

```text
version() -> string
```

to read which build version of the contract they are talking to.


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

The registry tests include root rotation checks, which prove that proofs for an
old root fail after `activeRoot` is updated.

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
make test-all
```

`make test` is an alias for `make test-all`, and the GitHub Actions workflow uses
that same full target.

Regenerate the Solidity build version file only:

```bash
make generate-build-info
```

## On-Chain Smoke

Run the full end-to-end flow against the live SwissLedger chain (id 110):

```bash
./scripts/on-chain-smoke                          # deploy fresh contract
./scripts/on-chain-smoke 0x20f89...1888b          # reuse existing contract
```

Compiles for pre-Shanghai EVM, deploys `MerkleRootRegistry`, sets a Merkle root,
and verifies both valid and invalid proofs on-chain. Every operation is timed.

Typical timings (ledger.swiss, Jun 2026):

| step                |    ms | status  |
|---------------------|-------|---------|
| build (istanbul)    |   165 | ok      |
| proxy start         |   674 | ok      |
| tree + proof        |   451 | ok      |
| setActiveRoot        | 6,550 | ok      |
| verify valid proof  |   287 | pass    |
| verify invalid proof|   300 | pass    |

# Licensing

Swissledger Merkle is Copyright (C) 2026 PlanB Foundation

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU Affero General Public License as
published by the Free Software Foundation, either version 3 of the
License, or (at your option) any later version.

This program is distributed in the hope that it will be useful, but
WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
Affero General Public License for more details.

You should have received a copy of the GNU Affero General Public
License along with this program.  If not, see
<https://www.gnu.org/licenses/>.

Includes code that is (C) 2022-2023 zOS Global Limited and contributors

Permission is hereby granted, free of charge, to any person obtaining
a copy of this software and associated documentation files (the
"Software"), to deal in the Software without restriction, including
without limitation the rights to use, copy, modify, merge, publish,
distribute, sublicense, and/or sell copies of the Software, and to
permit persons to whom the Software is furnished to do so, subject to
the following conditions:

The above copyright notice and this permission notice shall be
included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
