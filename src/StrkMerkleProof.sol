// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import {StarknetPedersen} from "./hash/StarknetPedersen.sol";

library StrkMerkleProof {
    /// @notice Rebuilds a Merkle root from a canonical single-leaf proof.
    function processProof(uint256 leafHash, uint256[] memory proof) internal pure returns (uint256) {
        uint256 computedHash = leafHash;

        for (uint256 index = 0; index < proof.length; index++) {
            computedHash = _hashSortedPair(computedHash, proof[index]);
        }

        return computedHash;
    }

    /// @notice Checks whether a leaf hash is included in the root under strk-merkle-tree semantics.
    function verify(uint256 root, uint256 leafHash, uint256[] memory proof) internal pure returns (bool) {
        return processProof(leafHash, proof) == root;
    }

    /// @notice Rebuilds a root from a canonical multiproof when the proof shape is valid.
    function processMultiProof(
        uint256[] memory leaves,
        uint256[] memory proof,
        bool[] memory proofFlags
    ) internal pure returns (uint256) {
        if (!_isValidMultiProofFormat(leaves.length, proof.length, proofFlags)) {
            revert("Invalid multiproof format");
        }

        return _processMultiProof(leaves, proof, proofFlags);
    }

    /// @notice Checks whether a set of leaf hashes is included in the root under strk-merkle-tree semantics.
    function verifyMultiProof(
        uint256 root,
        uint256[] memory leaves,
        uint256[] memory proof,
        bool[] memory proofFlags
    ) internal pure returns (bool) {
        if (!_isValidMultiProofFormat(leaves.length, proof.length, proofFlags)) {
            return false;
        }

        return _processMultiProof(leaves, proof, proofFlags) == root;
    }

    /// @dev Mirrors the library's queue-based multiproof processing.
    function _processMultiProof(
        uint256[] memory leaves,
        uint256[] memory proof,
        bool[] memory proofFlags
    ) private pure returns (uint256) {
        uint256 leavesLength = leaves.length;
        uint256 totalHashes = proofFlags.length;

        if (totalHashes == 0) {
            return leavesLength > 0 ? leaves[0] : proof[0];
        }

        uint256[] memory hashes = new uint256[](totalHashes);
        uint256 leafPos = 0;
        uint256 hashPos = 0;
        uint256 proofPos = 0;

        for (uint256 index = 0; index < totalHashes; index++) {
            uint256 a = leafPos < leavesLength ? leaves[leafPos++] : hashes[hashPos++];
            uint256 b = proofFlags[index]
                ? (leafPos < leavesLength ? leaves[leafPos++] : hashes[hashPos++])
                : proof[proofPos++];

            hashes[index] = _hashSortedPair(a, b);
        }

        return hashes[totalHashes - 1];
    }

    /// @dev A well-formed multiproof must satisfy the same length invariants as strk-merkle-tree.
    function _isValidMultiProofFormat(
        uint256 leavesLength,
        uint256 proofLength,
        bool[] memory proofFlags
    ) private pure returns (bool) {
        uint256 falseFlags = 0;

        for (uint256 index = 0; index < proofFlags.length; index++) {
            if (!proofFlags[index]) {
                falseFlags += 1;
            }
        }

        if (proofLength < falseFlags) {
            return false;
        }

        return leavesLength + proofLength == proofFlags.length + 1;
    }

    /// @dev Parent hashes are computed on the sorted pair, matching standardNodeHash.
    function _hashSortedPair(uint256 left, uint256 right) private pure returns (uint256) {
        return left <= right
            ? StarknetPedersen.hashPair(left, right)
            : StarknetPedersen.hashPair(right, left);
    }
}
