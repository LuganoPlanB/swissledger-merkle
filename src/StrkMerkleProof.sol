// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import {StarknetPedersen} from "./hash/StarknetPedersen.sol";

library StrkMerkleProof {
    function processProof(uint256 leafHash, uint256[] memory proof) internal pure returns (uint256) {
        uint256 computedHash = leafHash;

        for (uint256 index = 0; index < proof.length; index++) {
            uint256 sibling = proof[index];
            (uint256 left, uint256 right) = computedHash <= sibling
                ? (computedHash, sibling)
                : (sibling, computedHash);

            computedHash = StarknetPedersen.hashPair(left, right);
        }

        return computedHash;
    }

    function verify(uint256 root, uint256 leafHash, uint256[] memory proof) internal pure returns (bool) {
        return processProof(leafHash, proof) == root;
    }
}
