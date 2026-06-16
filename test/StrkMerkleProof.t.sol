// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import {StrkMerkleProof} from "../src/StrkMerkleProof.sol";

contract StrkMerkleProofTest {
    function testVerifyOneLeafTree() external pure {
        uint256 root = 0x0693e6761b37d88d77eb11e42e2fed1452bc5aa8a1566f5d5e4ec3c123e5aa04;
        uint256 leafHash = root;
        uint256[] memory proof = new uint256[](0);

        require(StrkMerkleProof.verify(root, leafHash, proof), "one-leaf proof failed");
    }

    function testVerifyTwoLeafTree() external pure {
        uint256 root = 0x0354b09ac3a192e45433a9fa81a366283e230999522af8f8a249f2a1982f6863;
        uint256 leafHash = 0x0693e6761b37d88d77eb11e42e2fed1452bc5aa8a1566f5d5e4ec3c123e5aa04;
        uint256[] memory proof = new uint256[](1);
        proof[0] = 0x015bf386477e7948a51fd27848739f156fb2bb3907e62c326d90f5f71d07e858;

        require(StrkMerkleProof.verify(root, leafHash, proof), "two-leaf proof failed");
    }

    function testVerifyFourLeafTree() external pure {
        uint256 root = 0x026a23d0b11e788fb6e263f29efb010f0f7455b9c69431aa0b40a91ffac80f8d;
        uint256 leafHash = 0x01264b5e40436dd2d91ee3254ec814b097961884a7e37a9965b7cf7b2646b9b9;
        uint256[] memory proof = new uint256[](2);
        proof[0] = 0x01a1b7703f2c66869de53da0855f30fd376e40f6c142a5d74a80cb7d4ee0b5e3;
        proof[1] = 0x987cd9c047f028ef8704bbbaecc9196d0a8fb89120d837955b4eb0fa640ca8;

        require(StrkMerkleProof.verify(root, leafHash, proof), "four-leaf proof failed");
    }

    function testRejectWrongLeaf() external pure {
        uint256 root = 0x026a23d0b11e788fb6e263f29efb010f0f7455b9c69431aa0b40a91ffac80f8d;
        uint256 leafHash = 0x01264b5e40436dd2d91ee3254ec814b097961884a7e37a9965b7cf7b2646b9ba;
        uint256[] memory proof = new uint256[](2);
        proof[0] = 0x01a1b7703f2c66869de53da0855f30fd376e40f6c142a5d74a80cb7d4ee0b5e3;
        proof[1] = 0x987cd9c047f028ef8704bbbaecc9196d0a8fb89120d837955b4eb0fa640ca8;

        require(!StrkMerkleProof.verify(root, leafHash, proof), "wrong leaf accepted");
    }

    function testRejectWrongRoot() external pure {
        uint256 root = 0x026a23d0b11e788fb6e263f29efb010f0f7455b9c69431aa0b40a91ffac80f8e;
        uint256 leafHash = 0x01264b5e40436dd2d91ee3254ec814b097961884a7e37a9965b7cf7b2646b9b9;
        uint256[] memory proof = new uint256[](2);
        proof[0] = 0x01a1b7703f2c66869de53da0855f30fd376e40f6c142a5d74a80cb7d4ee0b5e3;
        proof[1] = 0x987cd9c047f028ef8704bbbaecc9196d0a8fb89120d837955b4eb0fa640ca8;

        require(!StrkMerkleProof.verify(root, leafHash, proof), "wrong root accepted");
    }

    function testRejectReorderedProof() external pure {
        uint256 root = 0x026a23d0b11e788fb6e263f29efb010f0f7455b9c69431aa0b40a91ffac80f8d;
        uint256 leafHash = 0x01264b5e40436dd2d91ee3254ec814b097961884a7e37a9965b7cf7b2646b9b9;
        uint256[] memory proof = new uint256[](2);
        proof[0] = 0x987cd9c047f028ef8704bbbaecc9196d0a8fb89120d837955b4eb0fa640ca8;
        proof[1] = 0x01a1b7703f2c66869de53da0855f30fd376e40f6c142a5d74a80cb7d4ee0b5e3;

        require(!StrkMerkleProof.verify(root, leafHash, proof), "reordered proof accepted");
    }

    function testRejectTruncatedProof() external pure {
        uint256 root = 0x026a23d0b11e788fb6e263f29efb010f0f7455b9c69431aa0b40a91ffac80f8d;
        uint256 leafHash = 0x01264b5e40436dd2d91ee3254ec814b097961884a7e37a9965b7cf7b2646b9b9;
        uint256[] memory proof = new uint256[](1);
        proof[0] = 0x01a1b7703f2c66869de53da0855f30fd376e40f6c142a5d74a80cb7d4ee0b5e3;

        require(!StrkMerkleProof.verify(root, leafHash, proof), "truncated proof accepted");
    }

    function testRejectEmptyProofForNonLeafRoot() external pure {
        uint256 root = 0x0354b09ac3a192e45433a9fa81a366283e230999522af8f8a249f2a1982f6863;
        uint256 leafHash = 0x0693e6761b37d88d77eb11e42e2fed1452bc5aa8a1566f5d5e4ec3c123e5aa04;
        uint256[] memory proof = new uint256[](0);

        require(!StrkMerkleProof.verify(root, leafHash, proof), "empty proof accepted");
    }
}
