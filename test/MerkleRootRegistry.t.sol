// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import {MerkleRootRegistry} from "../src/MerkleRootRegistry.sol";

contract MerkleRootRegistryTest {
    function testNotarizeRoot() external {
        MerkleRootRegistry registry = new MerkleRootRegistry();
        bytes32 root = bytes32(uint256(0x0354b09ac3a192e45433a9fa81a366283e230999522af8f8a249f2a1982f6863));

        registry.notarizeRoot(root);

        require(registry.notarizedRoots(root), "root not notarized");
    }

    function testRejectZeroRoot() external {
        MerkleRootRegistry registry = new MerkleRootRegistry();

        (bool ok, ) = address(registry).call(
            abi.encodeCall(MerkleRootRegistry.notarizeRoot, (bytes32(0)))
        );

        require(!ok, "zero root accepted");
    }

    function testContainsReturnsTrueForValidNotarizedProof() external {
        MerkleRootRegistry registry = new MerkleRootRegistry();
        bytes32 root = bytes32(uint256(0x026a23d0b11e788fb6e263f29efb010f0f7455b9c69431aa0b40a91ffac80f8d));
        bytes32 leafHash = bytes32(
            uint256(0x01264b5e40436dd2d91ee3254ec814b097961884a7e37a9965b7cf7b2646b9b9)
        );
        bytes32[] memory proof = new bytes32[](2);
        proof[0] = bytes32(
            uint256(0x01a1b7703f2c66869de53da0855f30fd376e40f6c142a5d74a80cb7d4ee0b5e3)
        );
        proof[1] = bytes32(uint256(0x987cd9c047f028ef8704bbbaecc9196d0a8fb89120d837955b4eb0fa640ca8));

        registry.notarizeRoot(root);

        require(registry.contains(root, leafHash, proof), "valid proof rejected");
    }

    function testContainsReturnsFalseForValidProofAgainstNonNotarizedRoot() external {
        MerkleRootRegistry registry = new MerkleRootRegistry();
        bytes32 root = bytes32(uint256(0x026a23d0b11e788fb6e263f29efb010f0f7455b9c69431aa0b40a91ffac80f8d));
        bytes32 leafHash = bytes32(
            uint256(0x01264b5e40436dd2d91ee3254ec814b097961884a7e37a9965b7cf7b2646b9b9)
        );
        bytes32[] memory proof = new bytes32[](2);
        proof[0] = bytes32(
            uint256(0x01a1b7703f2c66869de53da0855f30fd376e40f6c142a5d74a80cb7d4ee0b5e3)
        );
        proof[1] = bytes32(uint256(0x987cd9c047f028ef8704bbbaecc9196d0a8fb89120d837955b4eb0fa640ca8));

        require(!registry.contains(root, leafHash, proof), "non-notarized root accepted");
    }

    function testContainsReturnsFalseForWrongLeaf() external {
        MerkleRootRegistry registry = new MerkleRootRegistry();
        bytes32 root = bytes32(uint256(0x026a23d0b11e788fb6e263f29efb010f0f7455b9c69431aa0b40a91ffac80f8d));
        bytes32 leafHash = bytes32(
            uint256(0x01264b5e40436dd2d91ee3254ec814b097961884a7e37a9965b7cf7b2646b9ba)
        );
        bytes32[] memory proof = new bytes32[](2);
        proof[0] = bytes32(
            uint256(0x01a1b7703f2c66869de53da0855f30fd376e40f6c142a5d74a80cb7d4ee0b5e3)
        );
        proof[1] = bytes32(uint256(0x987cd9c047f028ef8704bbbaecc9196d0a8fb89120d837955b4eb0fa640ca8));

        registry.notarizeRoot(root);

        require(!registry.contains(root, leafHash, proof), "wrong leaf accepted");
    }

    function testContainsReturnsFalseForWrongRoot() external {
        MerkleRootRegistry registry = new MerkleRootRegistry();
        bytes32 notarizedRoot = bytes32(
            uint256(0x026a23d0b11e788fb6e263f29efb010f0f7455b9c69431aa0b40a91ffac80f8d)
        );
        bytes32 requestedRoot = bytes32(
            uint256(0x026a23d0b11e788fb6e263f29efb010f0f7455b9c69431aa0b40a91ffac80f8e)
        );
        bytes32 leafHash = bytes32(
            uint256(0x01264b5e40436dd2d91ee3254ec814b097961884a7e37a9965b7cf7b2646b9b9)
        );
        bytes32[] memory proof = new bytes32[](2);
        proof[0] = bytes32(
            uint256(0x01a1b7703f2c66869de53da0855f30fd376e40f6c142a5d74a80cb7d4ee0b5e3)
        );
        proof[1] = bytes32(uint256(0x987cd9c047f028ef8704bbbaecc9196d0a8fb89120d837955b4eb0fa640ca8));

        registry.notarizeRoot(notarizedRoot);

        require(!registry.contains(requestedRoot, leafHash, proof), "wrong root accepted");
    }

    function testContainsReturnsFalseForInvalidProof() external {
        MerkleRootRegistry registry = new MerkleRootRegistry();
        bytes32 root = bytes32(uint256(0x026a23d0b11e788fb6e263f29efb010f0f7455b9c69431aa0b40a91ffac80f8d));
        bytes32 leafHash = bytes32(
            uint256(0x01264b5e40436dd2d91ee3254ec814b097961884a7e37a9965b7cf7b2646b9b9)
        );
        bytes32[] memory proof = new bytes32[](2);
        proof[0] = bytes32(uint256(0x01));
        proof[1] = bytes32(uint256(0x987cd9c047f028ef8704bbbaecc9196d0a8fb89120d837955b4eb0fa640ca8));

        registry.notarizeRoot(root);

        require(!registry.contains(root, leafHash, proof), "invalid proof accepted");
    }
}
