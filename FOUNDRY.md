# swissledger-cast — Fixes Required for ledger.swiss (chain id 110)

This document describes every RPC incompatibility between upstream
Foundry (`forge`, `cast`) and the SwissLedger chain (id 110).  These
must be fixed in the forked binaries published at
<https://github.com/LuganoPlanB/swissledger-foundry/releases>.

Reference version: **Foundry 1.7.1** (commit `4072e48705`).

---

## P0: JSON-RPC request must always include `"params"`

### Problem

Upstream `cast` and `forge` omit the `"params"` key for zero-parameter
JSON-RPC methods (`eth_blockNumber`, `eth_chainId`, `eth_gasPrice`,
`eth_maxPriorityFeePerGas`).  Per JSON-RPC 2.0 this is valid, but the
chain's Blockscout RPC endpoint requires it.

### Reproduction

```bash
cast block-number --rpc-url https://explorer.ledger.swiss/api/eth-rpc
cast chain-id    --rpc-url https://explorer.ledger.swiss/api/eth-rpc
```

### What cast sends (broken)

```json
{"method":"eth_blockNumber","id":0,"jsonrpc":"2.0"}
```

### What the server expects (working)

```json
{"method":"eth_blockNumber","params":[],"id":0,"jsonrpc":"2.0"}
```

### Fix

In the JSON-RPC request builder (likely `alloy-json-rpc` or
`alloy-transport` crate), always emit `"params"` for every request.
For methods with no arguments, emit `"params":[]`.

---

## P0: Accept non-standard error response format

### Problem

When the chain returns an error, it uses a plain string instead of the
standard JSON-RPC 2.0 error object:

```json
{"jsonrpc":"2.0","error": "Method, params, and jsonrpc, are all required parameters.","id": 0}
```

Standard JSON-RPC 2.0 errors must be:

```json
{"jsonrpc":"2.0","error": {"code": -32600, "message": "Invalid Request"}, "id": 0}
```

Upstream `cast`/`forge` crash with:

```
deserialization error: invalid type: string "…", expected a JSON-RPC 2.0
error object at line 1 column 85
```

### Fix

Make the `error` field deserialisation lenient.  Accept both:
- Standard: `{"code": int, "message": string, "data": ...}`
- Non-standard plain string

When a plain-string error is received, wrap it:

```json
{"code": -32000, "message": "<string content>"}
```

The relevant code is in `alloy-json-rpc` or `alloy-transport`, in the
`RpcError` or `ErrorPayload` types.

---

## P1: `forge build --evm-version` must override `foundry.toml`

### Problem

`forge build --evm-version istanbul` ignores the CLI flag when
`foundry.toml` sets `evm_version = "cancun"` in `[profile.default]`.

### Reproduction

```bash
# foundry.toml has evm_version = "cancun"
forge build --evm-version istanbul
forge inspect MerkleRootRegistry bytecode  # still has PUSH0 opcodes
```

### Fix (applied in swissledger-forge)

Ensure `--evm-version <VERSION>` on `forge build` takes precedence
over `foundry.toml`.  With `evm_version = "istanbul"` in `foundry.toml`
this is no longer needed — the default already matches the chain.

---

## P1: `cast call` / `cast calldata` array parsing ✅ FIXED

`swissledger-cast` now handles `bytes32[]` arguments natively — the
parser bug that required manual calldata encoding is resolved.

---

## P2: Fall back to 0 gas price on `eth_gasPrice` error ✅ FIXED

### Problem

The chain's `eth_gasPrice` returns HTTP 500:

```
"Internal server error"
```

Upstream treats this as a fatal error.

### Fix

When `eth_gasPrice` fails and the caller explicitly passed
`--legacy --gas-price 0`, treat the failure as equivalent to `0x0`.
A chain that errors on `eth_gasPrice` is signalling gas price is
irrelevant.

---

## P2: Fall back to user gas limit on `eth_estimateGas` error

### Problem

`eth_estimateGas` is rejected with:

```json
{"jsonrpc":"2.0","error": "Incorrect number of params.","id": 1}
```

### Fix

If `eth_estimateGas` fails, fall back to the user-provided
`--gas-limit` instead of aborting.

---

## Quick verification checklist

After applying fixes, run against the live chain:

```bash
# Should print the chain's current block number
cast block-number --rpc-url https://explorer.ledger.swiss/api/eth-rpc

# Should print chain id 110 (0x6e)
cast chain-id --rpc-url https://explorer.ledger.swiss/api/eth-rpc

# Should return the version string from the deployed contract
cast call 0x20f8905c787D02C57c414BC0DFB61a0b7C1888b "version()(string)" \
  --rpc-url https://explorer.ledger.swiss/api/eth-rpc
```

All three must succeed without errors before publishing the release.
