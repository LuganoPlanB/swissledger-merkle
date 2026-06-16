// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import {StrkMerkleProof} from "../src/StrkMerkleProof.sol";

contract StrkMerkleMultiProofTest {
    function testVerifyCanonicalAdjacentMultiproof() external pure {
        uint256 root = 0x026a23d0b11e788fb6e263f29efb010f0f7455b9c69431aa0b40a91ffac80f8d;
        uint256[] memory leaves = new uint256[](2);
        leaves[0] = 0x01264b5e40436dd2d91ee3254ec814b097961884a7e37a9965b7cf7b2646b9b9;
        leaves[1] = 0x01a1b7703f2c66869de53da0855f30fd376e40f6c142a5d74a80cb7d4ee0b5e3;

        uint256[] memory proof = new uint256[](1);
        proof[0] = 0x987cd9c047f028ef8704bbbaecc9196d0a8fb89120d837955b4eb0fa640ca8;

        bool[] memory proofFlags = new bool[](2);
        proofFlags[0] = true;
        proofFlags[1] = false;

        require(
            StrkMerkleProof.verifyMultiProof(root, leaves, proof, proofFlags),
            "adjacent multiproof failed"
        );
    }

    function testRejectWrongMultiproofLeafHash() external pure {
        uint256 root = 0x026a23d0b11e788fb6e263f29efb010f0f7455b9c69431aa0b40a91ffac80f8d;
        uint256[] memory leaves = new uint256[](2);
        leaves[0] = 0x01264b5e40436dd2d91ee3254ec814b097961884a7e37a9965b7cf7b2646b9ba;
        leaves[1] = 0x01a1b7703f2c66869de53da0855f30fd376e40f6c142a5d74a80cb7d4ee0b5e3;

        uint256[] memory proof = new uint256[](1);
        proof[0] = 0x987cd9c047f028ef8704bbbaecc9196d0a8fb89120d837955b4eb0fa640ca8;

        bool[] memory proofFlags = new bool[](2);
        proofFlags[0] = true;
        proofFlags[1] = false;

        require(
            !StrkMerkleProof.verifyMultiProof(root, leaves, proof, proofFlags),
            "wrong multiproof leaf accepted"
        );
    }

    function testRejectMalformedMultiproofFormat() external pure {
        uint256 root = 0x026a23d0b11e788fb6e263f29efb010f0f7455b9c69431aa0b40a91ffac80f8d;
        uint256[] memory leaves = new uint256[](2);
        leaves[0] = 0x01264b5e40436dd2d91ee3254ec814b097961884a7e37a9965b7cf7b2646b9b9;
        leaves[1] = 0x01a1b7703f2c66869de53da0855f30fd376e40f6c142a5d74a80cb7d4ee0b5e3;

        uint256[] memory proof = new uint256[](0);
        bool[] memory proofFlags = new bool[](2);
        proofFlags[0] = true;
        proofFlags[1] = false;

        require(
            !StrkMerkleProof.verifyMultiProof(root, leaves, proof, proofFlags),
            "malformed multiproof accepted"
        );
    }

    function testRejectQueueUnderflowMultiproofFormat() external pure {
        uint256 root = 0x026a23d0b11e788fb6e263f29efb010f0f7455b9c69431aa0b40a91ffac80f8d;
        uint256[] memory leaves = new uint256[](1);
        leaves[0] = 0x01264b5e40436dd2d91ee3254ec814b097961884a7e37a9965b7cf7b2646b9b9;

        uint256[] memory proof = new uint256[](1);
        proof[0] = 0x987cd9c047f028ef8704bbbaecc9196d0a8fb89120d837955b4eb0fa640ca8;

        bool[] memory proofFlags = new bool[](1);
        proofFlags[0] = true;

        require(
            !StrkMerkleProof.verifyMultiProof(root, leaves, proof, proofFlags),
            "queue underflow multiproof accepted"
        );
    }

    function testVerifyEmptySelectionMultiproof() external pure {
        uint256 root = 0x026a23d0b11e788fb6e263f29efb010f0f7455b9c69431aa0b40a91ffac80f8d;
        uint256[] memory leaves = new uint256[](0);
        uint256[] memory proof = new uint256[](1);
        proof[0] = root;
        bool[] memory proofFlags = new bool[](0);

        require(
            StrkMerkleProof.verifyMultiProof(root, leaves, proof, proofFlags),
            "empty multiproof failed"
        );
    }
}
