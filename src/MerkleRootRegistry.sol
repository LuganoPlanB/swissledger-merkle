// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import {StrkMerkleProof} from "./StrkMerkleProof.sol";

contract MerkleRootRegistry {
    error ZeroRoot();

    event RootNotarized(bytes32 indexed root, address indexed notarizer);

    mapping(bytes32 => bool) public notarizedRoots;

    function notarizeRoot(bytes32 root) external {
        if (root == bytes32(0)) {
            revert ZeroRoot();
        }

        notarizedRoots[root] = true;
        emit RootNotarized(root, msg.sender);
    }

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
}
