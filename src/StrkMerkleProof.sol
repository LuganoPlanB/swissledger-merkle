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
        (bool ok, uint256 rebuiltRoot) = _tryProcessMultiProof(leaves, proof, proofFlags);
        if (!ok) {
            revert("Invalid multiproof format");
        }

        return rebuiltRoot;
    }

    /// @notice Checks whether a set of leaf hashes is included in the root under strk-merkle-tree semantics.
    function verifyMultiProof(
        uint256 root,
        uint256[] memory leaves,
        uint256[] memory proof,
        bool[] memory proofFlags
    ) internal pure returns (bool) {
        (bool ok, uint256 rebuiltRoot) = _tryProcessMultiProof(leaves, proof, proofFlags);
        if (!ok) {
            return false;
        }

        return rebuiltRoot == root;
    }

    /// @dev Mirrors the library's queue-based multiproof processing and rejects queue underflow.
    function _tryProcessMultiProof(
        uint256[] memory leaves,
        uint256[] memory proof,
        bool[] memory proofFlags
    ) private pure returns (bool, uint256) {
        uint256 leavesLength = leaves.length;
        uint256 totalHashes = proofFlags.length;

        if (!_isValidMultiProofFormat(leavesLength, proof.length, proofFlags)) {
            return (false, 0);
        }

        if (totalHashes == 0) {
            return (true, leavesLength > 0 ? leaves[0] : proof[0]);
        }

        uint256[] memory hashes = new uint256[](totalHashes);
        uint256 leafPos = 0;
        uint256 hashPos = 0;
        uint256 hashesLength = 0;
        uint256 proofPos = 0;

        for (uint256 index = 0; index < totalHashes; index++) {
            (bool hasA, uint256 a) = _consumeQueueValue(leaves, leavesLength, leafPos, hashes, hashPos, hashesLength);
            if (!hasA) {
                return (false, 0);
            }
            if (leafPos < leavesLength) {
                leafPos += 1;
            } else {
                hashPos += 1;
            }

            uint256 b;
            if (proofFlags[index]) {
                (bool hasB, uint256 queueValue) =
                    _consumeQueueValue(leaves, leavesLength, leafPos, hashes, hashPos, hashesLength);
                if (!hasB) {
                    return (false, 0);
                }
                b = queueValue;

                if (leafPos < leavesLength) {
                    leafPos += 1;
                } else {
                    hashPos += 1;
                }
            } else {
                if (proofPos >= proof.length) {
                    return (false, 0);
                }
                b = proof[proofPos++];
            }

            hashes[index] = _hashSortedPair(a, b);
            hashesLength += 1;
        }

        if (proofPos != proof.length) {
            return (false, 0);
        }

        return (true, hashes[totalHashes - 1]);
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

    function _consumeQueueValue(
        uint256[] memory leaves,
        uint256 leavesLength,
        uint256 leafPos,
        uint256[] memory hashes,
        uint256 hashPos,
        uint256 hashesLength
    ) private pure returns (bool, uint256) {
        if (leafPos < leavesLength) {
            return (true, leaves[leafPos]);
        }
        if (hashPos < hashesLength) {
            return (true, hashes[hashPos]);
        }
        return (false, 0);
    }
}
