// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import {BuildInfo} from "../src/generated/BuildInfo.sol";
import {MerkleRootRegistry} from "../src/MerkleRootRegistry.sol";

contract UnauthorizedCaller {
    function trySetRoot(MerkleRootRegistry registry, bytes32 root) external returns (bool) {
        (bool ok, ) = address(registry).call(
            abi.encodeCall(MerkleRootRegistry.setActiveRoot, (root))
        );
        return ok;
    }

    function tryAddRootUpdater(MerkleRootRegistry registry, address updater) external returns (bool) {
        (bool ok, ) = address(registry).call(
            abi.encodeCall(MerkleRootRegistry.addRootUpdater, (updater))
        );
        return ok;
    }

    function tryRemoveRootUpdater(MerkleRootRegistry registry, address updater) external returns (bool) {
        (bool ok, ) = address(registry).call(
            abi.encodeCall(MerkleRootRegistry.removeRootUpdater, (updater))
        );
        return ok;
    }

    function tryTransferOwnership(MerkleRootRegistry registry, address newOwner) external returns (bool) {
        (bool ok, ) = address(registry).call(
            abi.encodeCall(MerkleRootRegistry.transferOwnership, (newOwner))
        );
        return ok;
    }

    function setRoot(MerkleRootRegistry registry, bytes32 root) external {
        registry.setActiveRoot(root);
    }
}

contract MerkleRootRegistryTest {
    uint256 private constant FIELD_PRIME =
        3618502788666131213697322783095070105623107215331596699973092056135872020481;

    function testSetActiveRoot() external {
        MerkleRootRegistry registry = new MerkleRootRegistry();
        bytes32 root = bytes32(uint256(0x0354b09ac3a192e45433a9fa81a366283e230999522af8f8a249f2a1982f6863));

        registry.setActiveRoot(root);

        require(registry.activeRoot() == root, "active root not updated");
    }

    function testOwnerStartsAsRootUpdater() external {
        MerkleRootRegistry registry = new MerkleRootRegistry();

        require(registry.isRootUpdater(address(this)), "owner not root updater");

        address[] memory updaters = registry.getRootUpdaters();
        require(updaters.length == 1, "unexpected updater count");
        require(updaters[0] == address(this), "unexpected initial updater");
    }

    function testRejectUnauthorizedSetActiveRoot() external {
        MerkleRootRegistry registry = new MerkleRootRegistry();
        bytes32 root = bytes32(uint256(0x0354b09ac3a192e45433a9fa81a366283e230999522af8f8a249f2a1982f6863));

        UnauthorizedCaller caller = new UnauthorizedCaller();
        bool ok = caller.trySetRoot(registry, root);

        require(!ok, "unauthorized root update accepted");
    }

    function testRejectUnauthorizedAddRootUpdater() external {
        MerkleRootRegistry registry = new MerkleRootRegistry();
        UnauthorizedCaller caller = new UnauthorizedCaller();

        bool ok = caller.tryAddRootUpdater(registry, address(caller));

        require(!ok, "unauthorized updater add accepted");
    }

    function testAddRootUpdaterAllowsRootRotation() external {
        MerkleRootRegistry registry = new MerkleRootRegistry();
        UnauthorizedCaller caller = new UnauthorizedCaller();
        bytes32 root = bytes32(uint256(0x0354b09ac3a192e45433a9fa81a366283e230999522af8f8a249f2a1982f6863));

        registry.addRootUpdater(address(caller));
        caller.setRoot(registry, root);

        require(registry.activeRoot() == root, "updater could not rotate root");
        require(registry.isRootUpdater(address(caller)), "updater not recorded");

        address[] memory updaters = registry.getRootUpdaters();
        require(updaters.length == 2, "updater list not extended");
    }

    function testRemoveRootUpdaterRevokesRootRotation() external {
        MerkleRootRegistry registry = new MerkleRootRegistry();
        UnauthorizedCaller caller = new UnauthorizedCaller();
        bytes32 root = bytes32(uint256(0x0354b09ac3a192e45433a9fa81a366283e230999522af8f8a249f2a1982f6863));

        registry.addRootUpdater(address(caller));
        registry.removeRootUpdater(address(caller));

        bool ok = caller.trySetRoot(registry, root);

        require(!ok, "removed updater still rotates root");
        require(!registry.isRootUpdater(address(caller)), "updater still recorded");
        require(registry.getRootUpdaters().length == 1, "updater list not shrunk");
    }

    function testTransferOwnershipMovesUpdaterPermission() external {
        MerkleRootRegistry registry = new MerkleRootRegistry();
        UnauthorizedCaller caller = new UnauthorizedCaller();

        registry.transferOwnership(address(caller));

        require(registry.owner() == address(caller), "owner not transferred");
        require(!registry.isRootUpdater(address(this)), "old owner still updater");
        require(registry.isRootUpdater(address(caller)), "new owner not updater");
    }

    function testVersion() external {
        MerkleRootRegistry registry = new MerkleRootRegistry();

        require(
            keccak256(bytes(registry.version())) == keccak256(bytes(BuildInfo.VERSION)),
            "unexpected registry version"
        );
    }
    function testRejectZeroRoot() external {
        MerkleRootRegistry registry = new MerkleRootRegistry();

        (bool ok, ) = address(registry).call(
            abi.encodeCall(MerkleRootRegistry.setActiveRoot, (bytes32(0)))
        );

        require(!ok, "zero root accepted");
    }

    function testRejectInvalidRootUpdater() external {
        MerkleRootRegistry registry = new MerkleRootRegistry();

        (bool ok, ) = address(registry).call(
            abi.encodeCall(MerkleRootRegistry.addRootUpdater, (address(0)))
        );

        require(!ok, "zero updater accepted");
    }

    function testContainsLeafHashReturnsFalseWithoutActiveRoot() external {
        MerkleRootRegistry registry = new MerkleRootRegistry();
        bytes32 leafHash = bytes32(
            uint256(0x01264b5e40436dd2d91ee3254ec814b097961884a7e37a9965b7cf7b2646b9b9)
        );
        bytes32[] memory proof = new bytes32[](2);
        proof[0] = bytes32(
            uint256(0x01a1b7703f2c66869de53da0855f30fd376e40f6c142a5d74a80cb7d4ee0b5e3)
        );
        proof[1] = bytes32(uint256(0x987cd9c047f028ef8704bbbaecc9196d0a8fb89120d837955b4eb0fa640ca8));

        require(!registry.containsLeafHash(leafHash, proof), "proof accepted without active root");
    }

    function testContainsLeafHashReturnsTrueForValidActiveProof() external {
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

        registry.setActiveRoot(root);

        require(registry.containsLeafHash(leafHash, proof), "valid proof rejected");
    }

    function testContainsReturnsTrueForValidRawHashProof() external {
        MerkleRootRegistry registry = new MerkleRootRegistry();
        bytes32 root = bytes32(uint256(0x015e318202e2b8729373651926fea9f3bc71c4d40ba07e1d4cd09049be91881e));
        bytes32 hashValue = bytes32(
            uint256(0x111111111111111111111111111111111111111111111111111111111111111)
        );
        bytes32[] memory proof = new bytes32[](1);
        proof[0] = bytes32(
            uint256(0x069c6299cfe8f9635173e58d1d0f087c35790ec02fe26e58565ccf636506c027)
        );

        registry.setActiveRoot(root);

        require(registry.contains(hashValue, proof), "valid hash proof rejected");
    }

    function testContainsReturnsFalseForWrongRawHash() external {
        MerkleRootRegistry registry = new MerkleRootRegistry();
        bytes32 root = bytes32(uint256(0x015e318202e2b8729373651926fea9f3bc71c4d40ba07e1d4cd09049be91881e));
        bytes32 hashValue = bytes32(
            uint256(0x333333333333333333333333333333333333333333333333333333333333333)
        );
        bytes32[] memory proof = new bytes32[](1);
        proof[0] = bytes32(
            uint256(0x069c6299cfe8f9635173e58d1d0f087c35790ec02fe26e58565ccf636506c027)
        );

        registry.setActiveRoot(root);

        require(!registry.contains(hashValue, proof), "wrong hash accepted");
    }

    function testContainsLeafHashReturnsFalseForWrongLeaf() external {
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

        registry.setActiveRoot(root);

        require(!registry.containsLeafHash(leafHash, proof), "wrong leaf accepted");
    }

    function testContainsLeafHashReturnsFalseForInvalidProof() external {
        MerkleRootRegistry registry = new MerkleRootRegistry();
        bytes32 root = bytes32(uint256(0x026a23d0b11e788fb6e263f29efb010f0f7455b9c69431aa0b40a91ffac80f8d));
        bytes32 leafHash = bytes32(
            uint256(0x01264b5e40436dd2d91ee3254ec814b097961884a7e37a9965b7cf7b2646b9b9)
        );
        bytes32[] memory proof = new bytes32[](2);
        proof[0] = bytes32(uint256(0x01));
        proof[1] = bytes32(uint256(0x987cd9c047f028ef8704bbbaecc9196d0a8fb89120d837955b4eb0fa640ca8));

        registry.setActiveRoot(root);

        require(!registry.containsLeafHash(leafHash, proof), "invalid proof accepted");
    }

    function testContainsLeafHashReturnsFalseAfterRootRotation() external {
        MerkleRootRegistry registry = new MerkleRootRegistry();
        bytes32 oldRoot = bytes32(uint256(0x026a23d0b11e788fb6e263f29efb010f0f7455b9c69431aa0b40a91ffac80f8d));
        bytes32 newRoot = bytes32(uint256(0x0354b09ac3a192e45433a9fa81a366283e230999522af8f8a249f2a1982f6863));
        bytes32 leafHash = bytes32(
            uint256(0x01264b5e40436dd2d91ee3254ec814b097961884a7e37a9965b7cf7b2646b9b9)
        );
        bytes32[] memory proof = new bytes32[](2);
        proof[0] = bytes32(
            uint256(0x01a1b7703f2c66869de53da0855f30fd376e40f6c142a5d74a80cb7d4ee0b5e3)
        );
        proof[1] = bytes32(uint256(0x987cd9c047f028ef8704bbbaecc9196d0a8fb89120d837955b4eb0fa640ca8));

        registry.setActiveRoot(oldRoot);
        require(registry.containsLeafHash(leafHash, proof), "old proof should verify before rotation");

        registry.setActiveRoot(newRoot);
        require(!registry.containsLeafHash(leafHash, proof), "old proof accepted after root rotation");
    }

    function testContainsLeafHashReturnsFalseForOutOfFieldLeafHash() external {
        MerkleRootRegistry registry = new MerkleRootRegistry();
        bytes32 root = bytes32(uint256(0x026a23d0b11e788fb6e263f29efb010f0f7455b9c69431aa0b40a91ffac80f8d));
        bytes32 leafHash = bytes32(FIELD_PRIME);
        bytes32[] memory proof = new bytes32[](2);
        proof[0] = bytes32(
            uint256(0x01a1b7703f2c66869de53da0855f30fd376e40f6c142a5d74a80cb7d4ee0b5e3)
        );
        proof[1] = bytes32(uint256(0x987cd9c047f028ef8704bbbaecc9196d0a8fb89120d837955b4eb0fa640ca8));

        registry.setActiveRoot(root);

        require(!registry.containsLeafHash(leafHash, proof), "out-of-field leaf hash accepted");
    }

    function testContainsReturnsFalseForOutOfFieldRawHash() external {
        MerkleRootRegistry registry = new MerkleRootRegistry();
        bytes32 root = bytes32(uint256(0x015e318202e2b8729373651926fea9f3bc71c4d40ba07e1d4cd09049be91881e));
        bytes32[] memory proof = new bytes32[](1);
        proof[0] = bytes32(
            uint256(0x069c6299cfe8f9635173e58d1d0f087c35790ec02fe26e58565ccf636506c027)
        );

        registry.setActiveRoot(root);

        require(!registry.contains(bytes32(FIELD_PRIME), proof), "out-of-field hash accepted");
    }

    function testContainsLeafHashReturnsFalseForOutOfFieldProofElement() external {
        MerkleRootRegistry registry = new MerkleRootRegistry();
        bytes32 root = bytes32(uint256(0x026a23d0b11e788fb6e263f29efb010f0f7455b9c69431aa0b40a91ffac80f8d));
        bytes32 leafHash = bytes32(
            uint256(0x01264b5e40436dd2d91ee3254ec814b097961884a7e37a9965b7cf7b2646b9b9)
        );
        bytes32[] memory proof = new bytes32[](2);
        proof[0] = bytes32(FIELD_PRIME);
        proof[1] = bytes32(uint256(0x987cd9c047f028ef8704bbbaecc9196d0a8fb89120d837955b4eb0fa640ca8));

        registry.setActiveRoot(root);

        require(!registry.containsLeafHash(leafHash, proof), "out-of-field proof accepted");
    }

    function testContainsManyReturnsTrueForValidActiveMultiproof() external {
        MerkleRootRegistry registry = new MerkleRootRegistry();
        bytes32 root = bytes32(uint256(0x026a23d0b11e788fb6e263f29efb010f0f7455b9c69431aa0b40a91ffac80f8d));
        bytes32[] memory leafHashes = new bytes32[](2);
        leafHashes[0] = bytes32(
            uint256(0x01264b5e40436dd2d91ee3254ec814b097961884a7e37a9965b7cf7b2646b9b9)
        );
        leafHashes[1] = bytes32(
            uint256(0x01a1b7703f2c66869de53da0855f30fd376e40f6c142a5d74a80cb7d4ee0b5e3)
        );

        bytes32[] memory proof = new bytes32[](1);
        proof[0] = bytes32(uint256(0x987cd9c047f028ef8704bbbaecc9196d0a8fb89120d837955b4eb0fa640ca8));

        bool[] memory proofFlags = new bool[](2);
        proofFlags[0] = true;
        proofFlags[1] = false;

        registry.setActiveRoot(root);

        require(registry.containsMany(leafHashes, proof, proofFlags), "valid multiproof rejected");
    }

    function testContainsManyReturnsFalseForWrongLeaf() external {
        MerkleRootRegistry registry = new MerkleRootRegistry();
        bytes32 root = bytes32(uint256(0x026a23d0b11e788fb6e263f29efb010f0f7455b9c69431aa0b40a91ffac80f8d));
        bytes32[] memory leafHashes = new bytes32[](2);
        leafHashes[0] = bytes32(
            uint256(0x01264b5e40436dd2d91ee3254ec814b097961884a7e37a9965b7cf7b2646b9ba)
        );
        leafHashes[1] = bytes32(
            uint256(0x01a1b7703f2c66869de53da0855f30fd376e40f6c142a5d74a80cb7d4ee0b5e3)
        );

        bytes32[] memory proof = new bytes32[](1);
        proof[0] = bytes32(uint256(0x987cd9c047f028ef8704bbbaecc9196d0a8fb89120d837955b4eb0fa640ca8));

        bool[] memory proofFlags = new bool[](2);
        proofFlags[0] = true;
        proofFlags[1] = false;

        registry.setActiveRoot(root);

        require(!registry.containsMany(leafHashes, proof, proofFlags), "wrong multiproof leaf accepted");
    }

    function testContainsManyReturnsFalseForMalformedFlags() external {
        MerkleRootRegistry registry = new MerkleRootRegistry();
        bytes32 root = bytes32(uint256(0x026a23d0b11e788fb6e263f29efb010f0f7455b9c69431aa0b40a91ffac80f8d));
        bytes32[] memory leafHashes = new bytes32[](2);
        leafHashes[0] = bytes32(
            uint256(0x01264b5e40436dd2d91ee3254ec814b097961884a7e37a9965b7cf7b2646b9b9)
        );
        leafHashes[1] = bytes32(
            uint256(0x01a1b7703f2c66869de53da0855f30fd376e40f6c142a5d74a80cb7d4ee0b5e3)
        );

        bytes32[] memory proof = new bytes32[](0);
        bool[] memory proofFlags = new bool[](2);
        proofFlags[0] = true;
        proofFlags[1] = false;

        registry.setActiveRoot(root);

        require(!registry.containsMany(leafHashes, proof, proofFlags), "malformed flags accepted");
    }

    function testContainsManyReturnsFalseForOutOfFieldLeafHash() external {
        MerkleRootRegistry registry = new MerkleRootRegistry();
        bytes32 root = bytes32(uint256(0x026a23d0b11e788fb6e263f29efb010f0f7455b9c69431aa0b40a91ffac80f8d));
        bytes32[] memory leafHashes = new bytes32[](2);
        leafHashes[0] = bytes32(FIELD_PRIME);
        leafHashes[1] = bytes32(
            uint256(0x01a1b7703f2c66869de53da0855f30fd376e40f6c142a5d74a80cb7d4ee0b5e3)
        );

        bytes32[] memory proof = new bytes32[](1);
        proof[0] = bytes32(uint256(0x987cd9c047f028ef8704bbbaecc9196d0a8fb89120d837955b4eb0fa640ca8));

        bool[] memory proofFlags = new bool[](2);
        proofFlags[0] = true;
        proofFlags[1] = false;

        registry.setActiveRoot(root);

        require(!registry.containsMany(leafHashes, proof, proofFlags), "out-of-field multiproof leaf accepted");
    }

    function testContainsManyReturnsFalseForOutOfFieldProofElement() external {
        MerkleRootRegistry registry = new MerkleRootRegistry();
        bytes32 root = bytes32(uint256(0x026a23d0b11e788fb6e263f29efb010f0f7455b9c69431aa0b40a91ffac80f8d));
        bytes32[] memory leafHashes = new bytes32[](2);
        leafHashes[0] = bytes32(
            uint256(0x01264b5e40436dd2d91ee3254ec814b097961884a7e37a9965b7cf7b2646b9b9)
        );
        leafHashes[1] = bytes32(
            uint256(0x01a1b7703f2c66869de53da0855f30fd376e40f6c142a5d74a80cb7d4ee0b5e3)
        );

        bytes32[] memory proof = new bytes32[](1);
        proof[0] = bytes32(FIELD_PRIME);

        bool[] memory proofFlags = new bool[](2);
        proofFlags[0] = true;
        proofFlags[1] = false;

        registry.setActiveRoot(root);

        require(!registry.containsMany(leafHashes, proof, proofFlags), "out-of-field multiproof proof accepted");
    }

    function testContainsManyReturnsFalseAfterRootRotation() external {
        MerkleRootRegistry registry = new MerkleRootRegistry();
        bytes32 oldRoot = bytes32(uint256(0x026a23d0b11e788fb6e263f29efb010f0f7455b9c69431aa0b40a91ffac80f8d));
        bytes32 newRoot = bytes32(uint256(0x0354b09ac3a192e45433a9fa81a366283e230999522af8f8a249f2a1982f6863));
        bytes32[] memory leafHashes = new bytes32[](2);
        leafHashes[0] = bytes32(
            uint256(0x01264b5e40436dd2d91ee3254ec814b097961884a7e37a9965b7cf7b2646b9b9)
        );
        leafHashes[1] = bytes32(
            uint256(0x01a1b7703f2c66869de53da0855f30fd376e40f6c142a5d74a80cb7d4ee0b5e3)
        );

        bytes32[] memory proof = new bytes32[](1);
        proof[0] = bytes32(uint256(0x987cd9c047f028ef8704bbbaecc9196d0a8fb89120d837955b4eb0fa640ca8));

        bool[] memory proofFlags = new bool[](2);
        proofFlags[0] = true;
        proofFlags[1] = false;

        registry.setActiveRoot(oldRoot);
        require(registry.containsMany(leafHashes, proof, proofFlags), "old multiproof should verify before rotation");

        registry.setActiveRoot(newRoot);
        require(!registry.containsMany(leafHashes, proof, proofFlags), "old multiproof accepted after root rotation");
    }
}
