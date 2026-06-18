<!--
SPDX-FileCopyrightText: 2026 PlanB foundation

SPDX-License-Identifier: AGPL-3.0-or-later
-->

# Merkle CLI

This directory contains the local Merkle client for `swissledger-merkle`.

It exposes a small shell-oriented CLI:

- `create-merkle-root`
- `create-merkle-proofs`
- `verify-merkle-proof`

All three commands are available through `npm run`.

## Setup

```bash
npm ci
```

## Help

```bash
npm run merkle -- --help
```

## Default Input Model

By default the CLI uses `["felt252"]` leaf encoding.

That means the values input can be a plain JSON array:

```json
["0x01", "0x02", "0x03"]
```

Internally each item becomes a single-field Merkle leaf.

## Commands

### Print a root

```bash
npm run create-merkle-root -- '["0x01","0x02","0x03"]'
```

Output:

```text
0x...
```

### Build a proof

The proof command takes:

1. the expected root
2. the full JSON array of values
3. the element to prove

```bash
ROOT="$(npm run --silent create-merkle-root -- '["0x01","0x02","0x03"]')"
npm run --silent create-merkle-proofs -- "$ROOT" '["0x01","0x02","0x03"]' '"0x02"'
```

Output:

```json
[
  "0x...",
  "0x..."
]
```

The command recomputes the tree from the provided values and fails if the
provided root does not match.

### Verify a proof

```bash
ROOT="$(npm run --silent create-merkle-root -- '["0x01","0x02","0x03"]')"
PROOF="$(npm run --silent create-merkle-proofs -- "$ROOT" '["0x01","0x02","0x03"]' '"0x02"')"
npm run --silent verify-merkle-proof -- "$ROOT" '"0x02"' "$PROOF"
```

Output:

```text
true
```

## Tuple Leaves

For non-`felt252` leaves, pass an explicit leaf encoding.

Example with `["ContractAddress","u128"]`:

```bash
VALUES='[
  ["0x1111111111111111111111111111111111111111", "10"],
  ["0x2222222222222222222222222222222222222222", "20"]
]'

npm run --silent merkle -- root "$VALUES" \
  --leaf-encoding '["ContractAddress","u128"]'
```

With multi-field leaves:

- the values input must be an array of tuples
- the element input must be one tuple

## Missing Piece To Be Aware Of

The only required extra parameter beyond `root`, `values`, `element`, and
`proof` is the leaf encoding when the leaves are not plain `felt252` values.
Without that, the same JSON value can hash differently depending on its field
types.
