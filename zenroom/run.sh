#!/usr/bin/env bash
set -euo pipefail

# Generate a temporary dir to put temporary files
TEMP=$(mktemp -d)
# OWNER_KEY without 0x (zenroom)
O_KEY=${OWNER_KEY#0x}
# Get the wallet address (from private key)
ADDR=$(cast wallet address --private-key "$OWNER_KEY")
# Retrieve the nonce
NONCE=$(cast nonce "$ADDR" --rpc-url "$RPC_URL")
# Retrieve the gas price
GAS=$(cast gas-price --rpc-url "$RPC_URL")

# Create the keyring and save it in the temporary directory
cat << EOF > "$TEMP/myKeyring.json"
{
    "keyring": {
            "ethereum": "$O_KEY"
    }
}
EOF


# Test addRootUpdater

# The zen file in the repo has chain ID 222 (the testnet) but in anvil is 31337
# (The file is saved in the temporary directory)
sed "s/chain '222'/chain '$CHAIN_ID'/" zenroom/add_newUpdater.zen > "$TEMP/add_newUpdater.zen"

# Create the input file (json)
cat << EOF > "$TEMP/add_newUpdater.json"
{
    "gas price": "$GAS",
    "gas limit": "300000",
    "ethereum nonce": "$NONCE",
    "contract_address": "$CONTRACT",
    "updater_address": "$UPDATER_ADDR"
}
EOF

# Sign the transaction
"$ZENROOM" -z -a "$TEMP/add_newUpdater.json" -k "$TEMP/myKeyring.json" -l zenroom/swiss_merkle.lua "$TEMP/add_newUpdater.zen" > "$TEMP/add_newUpdater_out.json"

# Publish the transaction
cast publish --rpc-url "$RPC_URL" "0x$(jq -r .signed_ethereum_transaction "$TEMP/add_newUpdater_out.json")"

# Check that the new updater is registered
cast call "$CONTRACT" 'isRootUpdater(address)(bool)' "$UPDATER_ADDR" --rpc-url "$RPC_URL" \
  |grep -q true || { echo "FAIL: updater not registered"; exit 1; }
echo "PASS: addRootUpdater"


# Test removeRootUpdater

# Retrieve the nonce
NONCE=$(cast nonce "$ADDR" --rpc-url "$RPC_URL")

# Correct the chain id
sed "s/chain '222'/chain '$CHAIN_ID'/" zenroom/remove_updater.zen > "$TEMP/remove_updater.zen"

# Create the input file
cat << EOF > "$TEMP/remove_updater.json"
{
    "gas price": "$GAS",
    "gas limit": "300000",
    "ethereum nonce": "$NONCE",
    "contract_address": "$CONTRACT",
    "updater_address": "$UPDATER_ADDR"
}
EOF

# Sign the transaction
"$ZENROOM" -z -a "$TEMP/remove_updater.json" -k "$TEMP/myKeyring.json" -l zenroom/swiss_merkle.lua "$TEMP/remove_updater.zen" > "$TEMP/remove_updater_out.json"

# Publish the transaction
cast publish --rpc-url "$RPC_URL" "0x$(jq -r .signed_ethereum_transaction "$TEMP/remove_updater_out.json")"

# Check that the updater is no longer registered
cast call "$CONTRACT" 'isRootUpdater(address)(bool)' "$UPDATER_ADDR" --rpc-url "$RPC_URL" \
  |grep -q false || { echo "FAIL: updater still registered"; exit 1; }
echo "PASS: removeRootUpdater"


# Test setActiveRoot

# Retrieve the nonce
NONCE=$(cast nonce "$ADDR" --rpc-url "$RPC_URL")

# The merkle root to set as active root
ROOT="0x0354b09ac3a192e45433a9fa81a366283e230999522af8f8a249f2a1982f6863"

# Correct the chain id
sed "s/chain '222'/chain '$CHAIN_ID'/" zenroom/set_root.zen > "$TEMP/set_root.zen"

# Create the input file
cat << EOF > "$TEMP/set_root.json"
{
    "gas price": "$GAS",
    "gas limit": "300000",
    "ethereum nonce": "$NONCE",
    "contract_address": "$CONTRACT",
    "root": "$ROOT"
}
EOF

# Sign the transaction
"$ZENROOM" -z -a "$TEMP/set_root.json" -k "$TEMP/myKeyring.json" -l zenroom/swiss_merkle.lua "$TEMP/set_root.zen" > "$TEMP/set_root_out.json"

# Publish the transaction
cast publish --rpc-url "$RPC_URL" "0x$(jq -r .signed_ethereum_transaction "$TEMP/set_root_out.json")"

# Check that the active root is correct
cast call "$CONTRACT" 'activeRoot()(bytes32)' --rpc-url "$RPC_URL" \
  |grep -q "$ROOT" || { echo "FAIL: active root not set"; exit 1; }
echo "PASS: setActiveRoot"


# Test transferOwnership

# Retrieve the nonce
NONCE=$(cast nonce "$ADDR" --rpc-url "$RPC_URL")

# Correct the chain id
sed "s/chain '222'/chain '$CHAIN_ID'/" zenroom/transfer_ownership.zen > "$TEMP/transfer_ownership.zen"

# Create the input file
cat << EOF > "$TEMP/transfer_ownership.json"
{
    "gas price": "$GAS",
    "gas limit": "300000",
    "ethereum nonce": "$NONCE",
    "contract_address": "$CONTRACT",
    "newOwner_address": "$UPDATER_ADDR"
}
EOF

# Sign the transaction
"$ZENROOM" -z -a "$TEMP/transfer_ownership.json" -k "$TEMP/myKeyring.json" -l zenroom/swiss_merkle.lua "$TEMP/transfer_ownership.zen" > "$TEMP/transfer_ownership_out.json"

# Publish the transaction
cast publish --rpc-url "$RPC_URL" "0x$(jq -r .signed_ethereum_transaction "$TEMP/transfer_ownership_out.json")"

# Check that the owner is the new address
cast call "$CONTRACT" 'owner()(address)' --rpc-url "$RPC_URL" \
  |grep -q "$UPDATER_ADDR" || { echo "FAIL: ownership not transferred"; exit 1; }
echo "PASS: transferOwnership"
