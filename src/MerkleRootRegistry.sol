// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import {StrkMerkleProof} from "./StrkMerkleProof.sol";

contract MerkleRootRegistry {
    error ZeroRoot();

    event RootNotarized(bytes32 indexed root, address indexed notarizer);

    mapping(bytes32 => bool) public notarizedRoots;

    /// @notice Stores a Merkle root so later membership checks can reference it on-chain.
    function notarizeRoot(bytes32 root) external {
        if (root == bytes32(0)) {
            revert ZeroRoot();
        }

        notarizedRoots[root] = true;
        emit RootNotarized(root, msg.sender);
    }

    /// @notice Checks whether a single leaf hash is included in a notarized root.
    function contains(bytes32 root, bytes32 leafHash, bytes32[] calldata proof) external view returns (bool) {
        if (!notarizedRoots[root]) {
            return false;
        }

        uint256[] memory feltProof = new uint256[](proof.length);
        for (uint256 index = 0; index < proof.length; index++) {
            feltProof[index] = uint256(proof[index]);
        }

        return StrkMerkleProof.verify(uint256(root), uint256(leafHash), feltProof);
    }

    /// @notice Checks whether a set of leaf hashes is included in a notarized root.
    function containsMany(
        bytes32 root,
        bytes32[] calldata leafHashes,
        bytes32[] calldata proof,
        bool[] calldata proofFlags
    ) external view returns (bool) {
        if (!notarizedRoots[root]) {
            return false;
        }

        uint256[] memory feltLeaves = new uint256[](leafHashes.length);
        for (uint256 index = 0; index < leafHashes.length; index++) {
            feltLeaves[index] = uint256(leafHashes[index]);
        }

        uint256[] memory feltProof = new uint256[](proof.length);
        for (uint256 index = 0; index < proof.length; index++) {
            feltProof[index] = uint256(proof[index]);
        }

        bool[] memory proofFlagsCopy = new bool[](proofFlags.length);
        for (uint256 index = 0; index < proofFlags.length; index++) {
            proofFlagsCopy[index] = proofFlags[index];
        }

        return StrkMerkleProof.verifyMultiProof(uint256(root), feltLeaves, feltProof, proofFlagsCopy);
    }
}
