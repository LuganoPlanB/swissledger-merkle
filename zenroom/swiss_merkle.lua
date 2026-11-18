-- Import crypto ethereum 
local ETH = require_once('crypto_ethereum')

local SL = {}
 
local MERKLE_REGISTRY_SIGNATURES = {
   owner             = { i={}, o={'address'}, view=true },
   activeRoot        = { i={}, o={'bytes32'}, view=true },
   isRootUpdater     = { i={'address'}, o={'bool'}, view=true },
   transferOwnership = { i={'address'}, o={} },
   addRootUpdater    = { i={'address'}, o={} },
   removeRootUpdater = { i={'address'}, o={} },
   getRootUpdaters   = { i={}, view=true, o={'address[]'} },
   version			 = { i={}, o={'string'}, view=true },
   setActiveRoot     = { i={'bytes32'}, o={}},
   containsLeafHash  = { i={'bytes32', 'bytes32[]'}, o={'bool'}, view=true },
   contains          = { i={'bytes32', 'bytes32[]'}, o={'bool'}, view=true },
   containsMany      = { i={'bytes32[]', 'bytes32[]','bool[]'}, o={'bool'}, view=true },
}

SL.merkle_registry = {}
for k, v in pairs(MERKLE_REGISTRY_SIGNATURES) do
	SL.merkle_registry[k] = ETH.data_contract_factory(k, v.i)
end 

-- Some functions don't have output
SL.merkle_registry_return = {}
for k, v in pairs(MERKLE_REGISTRY_SIGNATURES) do
	SL.merkle_registry_return[k] = ETH.contract_return_factory(v.o)
end 	

local data = SL.merkle_registry.version()

-- Function from zencode ethereum 
local function _use_eth_transaction(abi_fun, ...)
  local tx = have'ethereum transaction'
  zencode_assert(not tx.data or #tx.data == 0, "Cannot overwrite transaction data")
  tx.data = abi_fun(...)
end

-- When to add merkle updater
When("use ethereum transaction to add merkle updater ''", function(updater)
	_use_eth_transaction(SL.merkle_registry.addRootUpdater, have(updater))
end)

-- When to remove merkle updater
When("use ethereum transaction to remove merkle updater ''", function(updater)
	_use_eth_transaction(SL.merkle_registry.removeRootUpdater, have(updater))
end)

-- When to set a new active root
When("use ethereum transaction to set active root ''", function(root)
	_use_eth_transaction(SL.merkle_registry.setActiveRoot, have(root))
end)

--When to trasnfer the owsnership of the registry
When("use ethereum transaction to transfer ownership to ''", function(newowner)
	_use_eth_transaction(SL.merkle_registry.transferOwnership, have(newowner))
end)

return SL
