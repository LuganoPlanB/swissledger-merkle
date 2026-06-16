// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import {StrkMerkleProof} from "../../src/StrkMerkleProof.sol";

contract GeneratedMerkleParityTest {
    function test_one_leaf_u128_leaf_0() external pure {
        uint256 root = uint256(0x0693e6761b37d88d77eb11e42e2fed1452bc5aa8a1566f5d5e4ec3c123e5aa04);
        uint256 leafHash = uint256(0x0693e6761b37d88d77eb11e42e2fed1452bc5aa8a1566f5d5e4ec3c123e5aa04);
        uint256[] memory proof = new uint256[](0);
        require(StrkMerkleProof.verify(root, leafHash, proof), "generated proof failed");
    }

    function test_two_leaf_u128_leaf_0() external pure {
        uint256 root = uint256(0x0354b09ac3a192e45433a9fa81a366283e230999522af8f8a249f2a1982f6863);
        uint256 leafHash = uint256(0x0693e6761b37d88d77eb11e42e2fed1452bc5aa8a1566f5d5e4ec3c123e5aa04);
        uint256[] memory proof = new uint256[](1);
        proof[0] = uint256(0x015bf386477e7948a51fd27848739f156fb2bb3907e62c326d90f5f71d07e858);
        require(StrkMerkleProof.verify(root, leafHash, proof), "generated proof failed");
    }

    function test_two_leaf_u128_leaf_1() external pure {
        uint256 root = uint256(0x0354b09ac3a192e45433a9fa81a366283e230999522af8f8a249f2a1982f6863);
        uint256 leafHash = uint256(0x015bf386477e7948a51fd27848739f156fb2bb3907e62c326d90f5f71d07e858);
        uint256[] memory proof = new uint256[](1);
        proof[0] = uint256(0x0693e6761b37d88d77eb11e42e2fed1452bc5aa8a1566f5d5e4ec3c123e5aa04);
        require(StrkMerkleProof.verify(root, leafHash, proof), "generated proof failed");
    }

    function test_four_leaf_u128_leaf_0() external pure {
        uint256 root = uint256(0x026a23d0b11e788fb6e263f29efb010f0f7455b9c69431aa0b40a91ffac80f8d);
        uint256 leafHash = uint256(0x07b1da63b7a8f5fd302edae6cf4913ecf0082a64190409d1ec8ffd23cee3efab);
        uint256[] memory proof = new uint256[](2);
        proof[0] = uint256(0x05920afe2ba39087066ca3ddfd77c5d252216d72af6ccab608a56a49876c5242);
        proof[1] = uint256(0x07cd655617801ba20d8b50962e56ea07429d1126a67e3512ca2534ef95c53646);
        require(StrkMerkleProof.verify(root, leafHash, proof), "generated proof failed");
    }

    function test_four_leaf_u128_leaf_1() external pure {
        uint256 root = uint256(0x026a23d0b11e788fb6e263f29efb010f0f7455b9c69431aa0b40a91ffac80f8d);
        uint256 leafHash = uint256(0x01a1b7703f2c66869de53da0855f30fd376e40f6c142a5d74a80cb7d4ee0b5e3);
        uint256[] memory proof = new uint256[](2);
        proof[0] = uint256(0x01264b5e40436dd2d91ee3254ec814b097961884a7e37a9965b7cf7b2646b9b9);
        proof[1] = uint256(0x987cd9c047f028ef8704bbbaecc9196d0a8fb89120d837955b4eb0fa640ca8);
        require(StrkMerkleProof.verify(root, leafHash, proof), "generated proof failed");
    }

    function test_four_leaf_u128_leaf_2() external pure {
        uint256 root = uint256(0x026a23d0b11e788fb6e263f29efb010f0f7455b9c69431aa0b40a91ffac80f8d);
        uint256 leafHash = uint256(0x01264b5e40436dd2d91ee3254ec814b097961884a7e37a9965b7cf7b2646b9b9);
        uint256[] memory proof = new uint256[](2);
        proof[0] = uint256(0x01a1b7703f2c66869de53da0855f30fd376e40f6c142a5d74a80cb7d4ee0b5e3);
        proof[1] = uint256(0x987cd9c047f028ef8704bbbaecc9196d0a8fb89120d837955b4eb0fa640ca8);
        require(StrkMerkleProof.verify(root, leafHash, proof), "generated proof failed");
    }

    function test_four_leaf_u128_leaf_3() external pure {
        uint256 root = uint256(0x026a23d0b11e788fb6e263f29efb010f0f7455b9c69431aa0b40a91ffac80f8d);
        uint256 leafHash = uint256(0x05920afe2ba39087066ca3ddfd77c5d252216d72af6ccab608a56a49876c5242);
        uint256[] memory proof = new uint256[](2);
        proof[0] = uint256(0x07b1da63b7a8f5fd302edae6cf4913ecf0082a64190409d1ec8ffd23cee3efab);
        proof[1] = uint256(0x07cd655617801ba20d8b50962e56ea07429d1126a67e3512ca2534ef95c53646);
        require(StrkMerkleProof.verify(root, leafHash, proof), "generated proof failed");
    }

    function test_four_leaf_u128_adjacent_middle_multiproof() external pure {
        uint256 root = uint256(0x026a23d0b11e788fb6e263f29efb010f0f7455b9c69431aa0b40a91ffac80f8d);
        uint256 wrongRoot = uint256(0x26a23d0b11e788fb6e263f29efb010f0f7455b9c69431aa0b40a91ffac80f8e);
        uint256[] memory leaves = new uint256[](2);
        leaves[0] = uint256(0x01264b5e40436dd2d91ee3254ec814b097961884a7e37a9965b7cf7b2646b9b9);
        leaves[1] = uint256(0x01a1b7703f2c66869de53da0855f30fd376e40f6c142a5d74a80cb7d4ee0b5e3);
        uint256[] memory proof = new uint256[](1);
        proof[0] = uint256(0x987cd9c047f028ef8704bbbaecc9196d0a8fb89120d837955b4eb0fa640ca8);
        bool[] memory proofFlags = new bool[](2);
        proofFlags[0] = true;
        proofFlags[1] = false;
        require(StrkMerkleProof.verifyMultiProof(root, leaves, proof, proofFlags), "generated multiproof failed");
        require(!StrkMerkleProof.verifyMultiProof(wrongRoot, leaves, proof, proofFlags), "wrong multiproof root accepted");
    }

    function test_four_leaf_u128_adjacent_middle_rejects_mutated_leaves() external pure {
        uint256 root = uint256(0x026a23d0b11e788fb6e263f29efb010f0f7455b9c69431aa0b40a91ffac80f8d);
        uint256[] memory leaves = new uint256[](2);
        leaves[0] = uint256(0x1264b5e40436dd2d91ee3254ec814b097961884a7e37a9965b7cf7b2646b9ba);
        leaves[1] = uint256(0x01a1b7703f2c66869de53da0855f30fd376e40f6c142a5d74a80cb7d4ee0b5e3);
        uint256[] memory proof = new uint256[](1);
        proof[0] = uint256(0x987cd9c047f028ef8704bbbaecc9196d0a8fb89120d837955b4eb0fa640ca8);
        bool[] memory proofFlags = new bool[](2);
        proofFlags[0] = true;
        proofFlags[1] = false;
        require(!StrkMerkleProof.verifyMultiProof(root, leaves, proof, proofFlags), "mutated multiproof leaves accepted");
    }

    function test_four_leaf_u128_adjacent_middle_rejects_mutated_flags() external pure {
        uint256 root = uint256(0x026a23d0b11e788fb6e263f29efb010f0f7455b9c69431aa0b40a91ffac80f8d);
        uint256[] memory leaves = new uint256[](2);
        leaves[0] = uint256(0x01264b5e40436dd2d91ee3254ec814b097961884a7e37a9965b7cf7b2646b9b9);
        leaves[1] = uint256(0x01a1b7703f2c66869de53da0855f30fd376e40f6c142a5d74a80cb7d4ee0b5e3);
        uint256[] memory proof = new uint256[](1);
        proof[0] = uint256(0x987cd9c047f028ef8704bbbaecc9196d0a8fb89120d837955b4eb0fa640ca8);
        bool[] memory proofFlags = new bool[](2);
        proofFlags[0] = false;
        proofFlags[1] = false;
        require(!StrkMerkleProof.verifyMultiProof(root, leaves, proof, proofFlags), "mutated multiproof flags accepted");
    }

    function test_four_leaf_u128_non_adjacent_edges_multiproof() external pure {
        uint256 root = uint256(0x026a23d0b11e788fb6e263f29efb010f0f7455b9c69431aa0b40a91ffac80f8d);
        uint256 wrongRoot = uint256(0x26a23d0b11e788fb6e263f29efb010f0f7455b9c69431aa0b40a91ffac80f8e);
        uint256[] memory leaves = new uint256[](2);
        leaves[0] = uint256(0x05920afe2ba39087066ca3ddfd77c5d252216d72af6ccab608a56a49876c5242);
        leaves[1] = uint256(0x07b1da63b7a8f5fd302edae6cf4913ecf0082a64190409d1ec8ffd23cee3efab);
        uint256[] memory proof = new uint256[](1);
        proof[0] = uint256(0x07cd655617801ba20d8b50962e56ea07429d1126a67e3512ca2534ef95c53646);
        bool[] memory proofFlags = new bool[](2);
        proofFlags[0] = true;
        proofFlags[1] = false;
        require(StrkMerkleProof.verifyMultiProof(root, leaves, proof, proofFlags), "generated multiproof failed");
        require(!StrkMerkleProof.verifyMultiProof(wrongRoot, leaves, proof, proofFlags), "wrong multiproof root accepted");
    }

    function test_four_leaf_u128_non_adjacent_edges_rejects_mutated_leaves() external pure {
        uint256 root = uint256(0x026a23d0b11e788fb6e263f29efb010f0f7455b9c69431aa0b40a91ffac80f8d);
        uint256[] memory leaves = new uint256[](2);
        leaves[0] = uint256(0x5920afe2ba39087066ca3ddfd77c5d252216d72af6ccab608a56a49876c5243);
        leaves[1] = uint256(0x07b1da63b7a8f5fd302edae6cf4913ecf0082a64190409d1ec8ffd23cee3efab);
        uint256[] memory proof = new uint256[](1);
        proof[0] = uint256(0x07cd655617801ba20d8b50962e56ea07429d1126a67e3512ca2534ef95c53646);
        bool[] memory proofFlags = new bool[](2);
        proofFlags[0] = true;
        proofFlags[1] = false;
        require(!StrkMerkleProof.verifyMultiProof(root, leaves, proof, proofFlags), "mutated multiproof leaves accepted");
    }

    function test_four_leaf_u128_non_adjacent_edges_rejects_mutated_flags() external pure {
        uint256 root = uint256(0x026a23d0b11e788fb6e263f29efb010f0f7455b9c69431aa0b40a91ffac80f8d);
        uint256[] memory leaves = new uint256[](2);
        leaves[0] = uint256(0x05920afe2ba39087066ca3ddfd77c5d252216d72af6ccab608a56a49876c5242);
        leaves[1] = uint256(0x07b1da63b7a8f5fd302edae6cf4913ecf0082a64190409d1ec8ffd23cee3efab);
        uint256[] memory proof = new uint256[](1);
        proof[0] = uint256(0x07cd655617801ba20d8b50962e56ea07429d1126a67e3512ca2534ef95c53646);
        bool[] memory proofFlags = new bool[](2);
        proofFlags[0] = false;
        proofFlags[1] = false;
        require(!StrkMerkleProof.verifyMultiProof(root, leaves, proof, proofFlags), "mutated multiproof flags accepted");
    }

    function test_four_leaf_u128_empty_selection_multiproof() external pure {
        uint256 root = uint256(0x026a23d0b11e788fb6e263f29efb010f0f7455b9c69431aa0b40a91ffac80f8d);
        uint256 wrongRoot = uint256(0x26a23d0b11e788fb6e263f29efb010f0f7455b9c69431aa0b40a91ffac80f8e);
        uint256[] memory leaves = new uint256[](0);
        uint256[] memory proof = new uint256[](1);
        proof[0] = uint256(0x026a23d0b11e788fb6e263f29efb010f0f7455b9c69431aa0b40a91ffac80f8d);
        bool[] memory proofFlags = new bool[](0);
        require(StrkMerkleProof.verifyMultiProof(root, leaves, proof, proofFlags), "generated multiproof failed");
        require(!StrkMerkleProof.verifyMultiProof(wrongRoot, leaves, proof, proofFlags), "wrong multiproof root accepted");
    }

    function test_odd_count_u256_bool_leaf_0() external pure {
        uint256 root = uint256(0x04f45d05a231de57f778e41c197e26c82fbf79776f61b8720c96eb55c076853e);
        uint256 leafHash = uint256(0x060a6156bc8ffa702028a2fd7c359b5b45b12f92655846df8a0dddb6219af196);
        uint256[] memory proof = new uint256[](1);
        proof[0] = uint256(0x0340f56d221f05b76ff51dfd185c569fda5878aa2d8216a9bb5e00d369ebd11d);
        require(StrkMerkleProof.verify(root, leafHash, proof), "generated proof failed");
    }

    function test_odd_count_u256_bool_leaf_1() external pure {
        uint256 root = uint256(0x04f45d05a231de57f778e41c197e26c82fbf79776f61b8720c96eb55c076853e);
        uint256 leafHash = uint256(0x02cedce65ae8739f4281e152fe0efe3a524c46d7621b1154e18b1554d2991394);
        uint256[] memory proof = new uint256[](2);
        proof[0] = uint256(0x0351bf9336fbe77f7f48eacc6967e3a72e963552f72dec940647e3339366f9a3);
        proof[1] = uint256(0x060a6156bc8ffa702028a2fd7c359b5b45b12f92655846df8a0dddb6219af196);
        require(StrkMerkleProof.verify(root, leafHash, proof), "generated proof failed");
    }

    function test_odd_count_u256_bool_leaf_2() external pure {
        uint256 root = uint256(0x04f45d05a231de57f778e41c197e26c82fbf79776f61b8720c96eb55c076853e);
        uint256 leafHash = uint256(0x0351bf9336fbe77f7f48eacc6967e3a72e963552f72dec940647e3339366f9a3);
        uint256[] memory proof = new uint256[](2);
        proof[0] = uint256(0x02cedce65ae8739f4281e152fe0efe3a524c46d7621b1154e18b1554d2991394);
        proof[1] = uint256(0x060a6156bc8ffa702028a2fd7c359b5b45b12f92655846df8a0dddb6219af196);
        require(StrkMerkleProof.verify(root, leafHash, proof), "generated proof failed");
    }

    function test_odd_count_u256_bool_outer_pair_multiproof() external pure {
        uint256 root = uint256(0x04f45d05a231de57f778e41c197e26c82fbf79776f61b8720c96eb55c076853e);
        uint256 wrongRoot = uint256(0x4f45d05a231de57f778e41c197e26c82fbf79776f61b8720c96eb55c076853f);
        uint256[] memory leaves = new uint256[](2);
        leaves[0] = uint256(0x0351bf9336fbe77f7f48eacc6967e3a72e963552f72dec940647e3339366f9a3);
        leaves[1] = uint256(0x060a6156bc8ffa702028a2fd7c359b5b45b12f92655846df8a0dddb6219af196);
        uint256[] memory proof = new uint256[](1);
        proof[0] = uint256(0x02cedce65ae8739f4281e152fe0efe3a524c46d7621b1154e18b1554d2991394);
        bool[] memory proofFlags = new bool[](2);
        proofFlags[0] = false;
        proofFlags[1] = true;
        require(StrkMerkleProof.verifyMultiProof(root, leaves, proof, proofFlags), "generated multiproof failed");
        require(!StrkMerkleProof.verifyMultiProof(wrongRoot, leaves, proof, proofFlags), "wrong multiproof root accepted");
    }

    function test_odd_count_u256_bool_outer_pair_rejects_mutated_leaves() external pure {
        uint256 root = uint256(0x04f45d05a231de57f778e41c197e26c82fbf79776f61b8720c96eb55c076853e);
        uint256[] memory leaves = new uint256[](2);
        leaves[0] = uint256(0x351bf9336fbe77f7f48eacc6967e3a72e963552f72dec940647e3339366f9a4);
        leaves[1] = uint256(0x060a6156bc8ffa702028a2fd7c359b5b45b12f92655846df8a0dddb6219af196);
        uint256[] memory proof = new uint256[](1);
        proof[0] = uint256(0x02cedce65ae8739f4281e152fe0efe3a524c46d7621b1154e18b1554d2991394);
        bool[] memory proofFlags = new bool[](2);
        proofFlags[0] = false;
        proofFlags[1] = true;
        require(!StrkMerkleProof.verifyMultiProof(root, leaves, proof, proofFlags), "mutated multiproof leaves accepted");
    }

    function test_odd_count_u256_bool_outer_pair_rejects_mutated_flags() external pure {
        uint256 root = uint256(0x04f45d05a231de57f778e41c197e26c82fbf79776f61b8720c96eb55c076853e);
        uint256[] memory leaves = new uint256[](2);
        leaves[0] = uint256(0x0351bf9336fbe77f7f48eacc6967e3a72e963552f72dec940647e3339366f9a3);
        leaves[1] = uint256(0x060a6156bc8ffa702028a2fd7c359b5b45b12f92655846df8a0dddb6219af196);
        uint256[] memory proof = new uint256[](1);
        proof[0] = uint256(0x02cedce65ae8739f4281e152fe0efe3a524c46d7621b1154e18b1554d2991394);
        bool[] memory proofFlags = new bool[](2);
        proofFlags[0] = true;
        proofFlags[1] = true;
        require(!StrkMerkleProof.verifyMultiProof(root, leaves, proof, proofFlags), "mutated multiproof flags accepted");
    }

    function test_duplicate_values_leaf_0() external pure {
        uint256 root = uint256(0x07828d9e9eb1fdff62a7cf6b76d6638e17636e5332536a1392faf0da3628bdcc);
        uint256 leafHash = uint256(0x04ece6f6500df9a8792421ca97e7f3cb509b7b90d2d4195febf6e081befc9669);
        uint256[] memory proof = new uint256[](2);
        proof[0] = uint256(0xd14ac34502424f83aa988905363e7511d82871c11a77c0273b266ceeac6515);
        proof[1] = uint256(0x04ece6f6500df9a8792421ca97e7f3cb509b7b90d2d4195febf6e081befc9669);
        require(StrkMerkleProof.verify(root, leafHash, proof), "generated proof failed");
    }

    function test_duplicate_values_leaf_1() external pure {
        uint256 root = uint256(0x07828d9e9eb1fdff62a7cf6b76d6638e17636e5332536a1392faf0da3628bdcc);
        uint256 leafHash = uint256(0x04ece6f6500df9a8792421ca97e7f3cb509b7b90d2d4195febf6e081befc9669);
        uint256[] memory proof = new uint256[](1);
        proof[0] = uint256(0x06a19e37e49667b83f04e42cc8847c610d33e1e68925555878bc794aaff2f144);
        require(StrkMerkleProof.verify(root, leafHash, proof), "generated proof failed");
    }

    function test_duplicate_values_leaf_2() external pure {
        uint256 root = uint256(0x07828d9e9eb1fdff62a7cf6b76d6638e17636e5332536a1392faf0da3628bdcc);
        uint256 leafHash = uint256(0xd14ac34502424f83aa988905363e7511d82871c11a77c0273b266ceeac6515);
        uint256[] memory proof = new uint256[](2);
        proof[0] = uint256(0x04ece6f6500df9a8792421ca97e7f3cb509b7b90d2d4195febf6e081befc9669);
        proof[1] = uint256(0x04ece6f6500df9a8792421ca97e7f3cb509b7b90d2d4195febf6e081befc9669);
        require(StrkMerkleProof.verify(root, leafHash, proof), "generated proof failed");
    }

}
