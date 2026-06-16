// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import {StrkMerkleProof} from "./StrkMerkleProof.sol";

contract MerkleRootRegistry {
    uint256 private constant FIELD_PRIME =
        3618502788666131213697322783095070105623107215331596699973092056135872020481;

    error ZeroRoot();

    event ActiveRootUpdated(bytes32 indexed previousRoot, bytes32 indexed newRoot, address indexed updater);

    bytes32 public activeRoot;

    /// @notice Replaces the current Merkle root with the latest off-chain state snapshot.
    function setActiveRoot(bytes32 newRoot) external {
        if (newRoot == bytes32(0)) {
            revert ZeroRoot();
        }

        bytes32 previousRoot = activeRoot;
        activeRoot = newRoot;
        emit ActiveRootUpdated(previousRoot, newRoot, msg.sender);
    }

    /// @notice Checks whether a single leaf hash is included in the latest active root.
    function contains(bytes32 leafHash, bytes32[] calldata proof) external view returns (bool) {
        bytes32 root = activeRoot;
        if (root == bytes32(0)) {
            return false;
        }

        if (!_isValidFelt(uint256(root)) || !_isValidFelt(uint256(leafHash))) {
            return false;
        }

        uint256[] memory feltProof = new uint256[](proof.length);
        for (uint256 index = 0; index < proof.length; index++) {
            uint256 proofValue = uint256(proof[index]);
            if (!_isValidFelt(proofValue)) {
                return false;
            }
            feltProof[index] = proofValue;
        }

        return StrkMerkleProof.verify(uint256(root), uint256(leafHash), feltProof);
    }

    /// @notice Checks whether a set of leaf hashes is included in the latest active root.
    function containsMany(
        bytes32[] calldata leafHashes,
        bytes32[] calldata proof,
        bool[] calldata proofFlags
    ) external view returns (bool) {
        bytes32 root = activeRoot;
        if (root == bytes32(0)) {
            return false;
        }

        if (!_isValidFelt(uint256(root))) {
            return false;
        }

        uint256[] memory feltLeaves = new uint256[](leafHashes.length);
        for (uint256 index = 0; index < leafHashes.length; index++) {
            uint256 leafValue = uint256(leafHashes[index]);
            if (!_isValidFelt(leafValue)) {
                return false;
            }
            feltLeaves[index] = leafValue;
        }

        uint256[] memory feltProof = new uint256[](proof.length);
        for (uint256 index = 0; index < proof.length; index++) {
            uint256 proofValue = uint256(proof[index]);
            if (!_isValidFelt(proofValue)) {
                return false;
            }
            feltProof[index] = proofValue;
        }

        bool[] memory proofFlagsCopy = new bool[](proofFlags.length);
        for (uint256 index = 0; index < proofFlags.length; index++) {
            proofFlagsCopy[index] = proofFlags[index];
        }

        return StrkMerkleProof.verifyMultiProof(uint256(root), feltLeaves, feltProof, proofFlagsCopy);
    }

    function _isValidFelt(uint256 value) private pure returns (bool) {
        return value < FIELD_PRIME;
    }
}
