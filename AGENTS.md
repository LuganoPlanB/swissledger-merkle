# Swissledger Merkle — Agent Reference

## Project Map

| Area | Path | What |
|---|---|---|
| Solidity contracts | `src/` | `MerkleRootRegistry.sol`, Pedersen hash libs, build info |
| Tests (Solidity) | `test/` | `forge test` via Foundry |
| Tests (Node) | `clients/merkle/*.test.mjs` | `node --test` |
| Off-chain client | `clients/merkle/merkle-cli.mjs` | Tree building, proof generation, verification |
| Vector fixtures | `fixtures/merkle/` | JS→Solidity parity test vectors |
| Scripts | `scripts/` | Keygen, e2e smoke, build-info gen |
| Config | `foundry.toml`, `package.json`, `GNUmakefile`, `mise.toml` |

## Quick Commands

```bash
make setup        # install deps + generate local EVM keys
make build        # regenerate BuildInfo.sol + forge build
make test         # full suite (client + solidity + parity + smoke)
make test-client  # Node.js tests only
make test-solidity # forge test only
make test-smoke   # local Anvil e2e deployment
```

## Architecture

**Active Root Model**: only one Merkle root (`activeRoot`) lives on-chain. Updating it invalidates all previous proofs. Storage is O(1).

- `MerkleRootRegistry` — the contract. Controls `activeRoot` and an owner-managed allowlist of root updaters.
- `StrkMerkleProof` — library matching `@ericnordelo/strk-merkle-tree` semantics (sorted-pair Pedersen hashing).
- `StarknetPedersen` / `EllipticCurve` — on-chain Pedersen hash implementation over the Starknet field prime.
- `BuildInfo` — auto-generated contract embedding the npm package version (exposed via `version()`).

## SwissLedger Chain (ledger.swiss)

### Chain identity

| Property | Value |
|---|---|
| Chain ID | `110` (0x6e) |
| Explorer | `https://explorer.ledger.swiss` |
| RPC endpoint | `https://explorer.ledger.swiss/api/eth-rpc` |
| Block gas limit | ~20,000,000 |
| Gas price | Always 0 (permissioned, gas-free) |
| EVM level | **Pre-Shanghai** (no `PUSH0`, no `MCOPY`) |
| Explorer API | Blockscout at `https://explorer.ledger.swiss/api` |

### EVM incompatibility: PUSH0 (Shanghai) and MCOPY (Cancun)

The chain does **not** support `PUSH0` (EIP-3855) or `MCOPY` (EIP-5656).
When these opcodes are hit during contract execution, the EVM treats them as
**INVALID** and consumes **all remaining gas** — the tx fails with exactly the
gas-limit consumed, no revert reason.

The repo's `foundry.toml` targets `evm_version = "cancun"` by default, which
causes solc ≥0.8.20 to emit `PUSH0` and `MCOPY` via the IR pipeline.

**Workaround**: compile targeting `london` or earlier EVM version:

```bash
forge build --evm-version london
```

The `via_ir` flag is still required (the Pedersen arith libs hit "stack too deep"
without it).  The combination `evm_version = "london"` + `via_ir = true` works.

Verify the bytecode has no forbidden opcodes:

```bash
# Should print 0 for both after a london build
forge inspect MerkleRootRegistry bytecode |
  python3 -c "
import sys
b = sys.stdin.read().strip()[2:]
i, push0, mcopy = 0, 0, 0
while i < len(b):
    op = int(b[i:i+2], 16)
    if op == 0x5f: push0 += 1; i += 2
    elif op == 0x5e: mcopy += 1; i += 2
    elif 0x60 <= op <= 0x7f: i += 2 + (op - 0x5f) * 2
    else: i += 2
print(f'PUSH0: {push0}, MCOPY: {mcopy}')
"
```

### RPC quirk: mandatory `params` field

The Blockscout `/api/eth-rpc` endpoint requires every JSON-RPC request to
include the `"params"` field, even when empty.  Standard JSON-RPC 2.0 allows
omitting it, so `forge` and `cast` skip `params` for zero-param methods
(`eth_blockNumber`, `eth_chainId`, `eth_gasPrice`, etc.).

This causes any `forge`/`cast` command that calls those methods to fail with:

```
deserialization error: invalid type: string "Method, params, and jsonrpc,
are all required parameters.", expected a JSON-RPC 2.0 error object
```

**Workaround A — manual deploy with `cast mktx` + `cast publish`**:

1. Create the signed tx against a **local mock** that returns compliant responses:

```bash
# Start mock RPC on port 9990 (one request then exits):
python3 -c "
import http.server, json, threading, time

class P(http.server.BaseHTTPRequestHandler):
    def do_POST(self):
        body = self.rfile.read(int(self.headers.get('Content-Length', 0)))
        data = json.loads(body)
        method = data.get('method', '')
        if method == 'eth_getTransactionCount':
            # return the correct nonce from the chain
            result = '0x4'
        else:
            result = '0x0'
        resp = {'jsonrpc':'2.0','result':result,'id':data.get('id',0)}
        self.send_response(200)
        self.send_header('Content-Type', 'application/json')
        self.end_headers()
        self.wfile.write(json.dumps(resp).encode())
    def log_message(self, *a): pass

s = http.server.HTTPServer(('127.0.0.1', 9990), P)
threading.Thread(target=s.handle_request, daemon=True).start()
time.sleep(0.1)
" &

SIGNED_TX=$(cast mktx \
  --rpc-url http://127.0.0.1:9990 \
  --private-key "0x…" \
  --gas-limit 3000000 \
  --gas-price 0 \
  --legacy \
  --nonce 4 \
  --chain 110 \
  --create "$BYTECODE")

cast publish --rpc-url https://explorer.ledger.swiss/api/eth-rpc "$SIGNED_TX"
```

2. `cast publish` only calls `eth_sendRawTransaction` (which has params), so it
   works directly against the real RPC.

**Workaround B — RPC params-injection proxy**:

The script `scripts/rpc-proxy.py` intercepts every JSON-RPC request and injects
`"params":[]` if the field is missing, then forwards to the real endpoint:

```bash
# Terminal 1
python3 scripts/rpc-proxy.py
# Listens on http://127.0.0.1:8545 → https://explorer.ledger.swiss/api/eth-rpc

# Terminal 2 — all forge/cast commands now work normally
forge create src/MerkleRootRegistry.sol:MerkleRootRegistry \
  --rpc-url http://127.0.0.1:8545 \
  --private-key "0x…" \
  --legacy \
  --broadcast
```

The proxy also handles the chain's non-standard error responses (plain string
`"error"` instead of `{"code":…, "message":…}` format expected by JSON-RPC 2.0),
which would otherwise cause deserialization errors in `forge`/`cast`.

### Deploying to ledger.swiss

Preconditions:
- Wallet registered on the chain (via the `FULL` registrar tx)
- Private key in `evm-private-key.txt` (generated by `scripts/keygen`)
- Build compiled for **london EVM** (see above)

Steps:

```bash
# 1. Compile for the chain's EVM level
forge build --evm-version london

# 2. Get bytecode
BYTECODE=$(forge inspect MerkleRootRegistry bytecode)

# 3. Create and send the deployment tx
#    (uses the mock-RPC trick; see Workaround A above)
#    Set NONCE to the current on-chain nonce:
#    curl -s -X POST "https://explorer.ledger.swiss/api/eth-rpc" \
#      -H "Content-Type: application/json" \
#      -d '{"jsonrpc":"2.0","method":"eth_getTransactionCount","params":["0x…","latest"],"id":1}'

SIGNED_TX=$(cast mktx \
  --rpc-url http://127.0.0.1:9990 \
  --private-key "0x…" \
  --gas-limit 3000000 \
  --gas-price 0 \
  --legacy \
  --nonce "$NONCE" \
  --chain 110 \
  --create "$BYTECODE")

cast publish \
  --rpc-url https://explorer.ledger.swiss/api/eth-rpc \
  "$SIGNED_TX"
```

**Important**:
- Always use `--legacy` (the chain rejects EIP-1559 type-2 transactions with
  "transaction type not supported").
- Always use `--gas-price 0` (the chain rejects non-zero gas price with
  "Gas price not 0").
- Gas limit ~3M is sufficient for `MerkleRootRegistry` (actual usage ~2M).
- The block gas limit is ~20M; the contract fits comfortably.
- Check transaction at `https://explorer.ledger.swiss/tx/<hash>`.
- If you see `status: "0x1"` and gas used well under the limit, it succeeded.
  If gas used equals the limit, the contract likely hit an unsupported opcode.

### Calling the deployed contract

Read-only calls work directly via the RPC:

```bash
# version()
curl -s -X POST "https://explorer.ledger.swiss/api/eth-rpc" \
  -H "Content-Type: application/json" \
  -d '{"jsonrpc":"2.0","method":"eth_call","params":[{"to":"0x…","data":"0x54fd4d50"},"latest"],"id":1}'

# owner()
curl -s -X POST "https://explorer.ledger.swiss/api/eth-rpc" \
  -H "Content-Type: application/json" \
  -d '{"jsonrpc":"2.0","method":"eth_call","params":[{"to":"0x…","data":"0x8da5cb5b"},"latest"],"id":1}'
```

State-changing calls (`setActiveRoot`, etc.) need signed transactions:

```bash
cast send "0x…" "setActiveRoot(bytes32)" "0x…ROOT…" \
  --rpc-url https://explorer.ledger.swiss/api/eth-rpc \
  --private-key "0x…" \
  --gas-limit 200000 \
  --gas-price 0 \
  --legacy
```

`cast send` works directly because `eth_sendRawTransaction` and
`eth_getTransactionCount` both include `params`, so the mandatory-params quirk
doesn't block them.

### Contract verification (Blockscout)

Verification via the API returns "Something went wrong" — the exact compiler
version string for the london build may need to be checked in the artifact
(`out/MerkleRootRegistry.sol/MerkleRootRegistry.json` → `metadata.compiler`).

The flattened source is at:

```bash
forge flatten src/MerkleRootRegistry.sol > /tmp/MerkleRootRegistry_flattened.sol
```

## Local Wallet

- `evm-private-key.txt` — private key (0x…)
- `evm-address.txt` — derived address
- `evm-wallet.json` — keystore (password: empty)
- Generated by `scripts/keygen` (gitignored)
- The address is registered on ledger.swiss via a `FULL` registrar call
  (see `https://explorer.ledger.swiss/tx/0x942b…`)

## Dependencies

- **Node 24** with ESM modules
- **Foundry** (`forge` + `cast`), installed by `scripts/install-deps`
- **Zenroom** + **Slangroom** (see `mise.toml`)
- No `ethers`/`hardhat`/`truffle` — Foundry-only for Solidity
