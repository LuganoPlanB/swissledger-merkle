// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import {StarknetPedersen} from "../src/hash/StarknetPedersen.sol";

contract StarknetPedersenHarness {
    function hashPair(uint256 left, uint256 right) external pure returns (uint256) {
        return StarknetPedersen.hashPair(left, right);
    }

    function hashFelt252Leaf(uint256 value) external pure returns (uint256) {
        return StarknetPedersen.hashFelt252Leaf(value);
    }
}

contract StarknetPedersenTest {
    StarknetPedersenHarness private harness = new StarknetPedersenHarness();

    function testHashPairMatchesTwoLeafVector() external pure {
        uint256 left = 0x015bf386477e7948a51fd27848739f156fb2bb3907e62c326d90f5f71d07e858;
        uint256 right = 0x0693e6761b37d88d77eb11e42e2fed1452bc5aa8a1566f5d5e4ec3c123e5aa04;
        uint256 expected = 0x0354b09ac3a192e45433a9fa81a366283e230999522af8f8a249f2a1982f6863;

        require(StarknetPedersen.hashPair(left, right) == expected, "two-leaf mismatch");
    }

    function testHashPairMatchesFourLeafVector() external pure {
        uint256 left = 0x01264b5e40436dd2d91ee3254ec814b097961884a7e37a9965b7cf7b2646b9b9;
        uint256 right = 0x01a1b7703f2c66869de53da0855f30fd376e40f6c142a5d74a80cb7d4ee0b5e3;
        uint256 expected = 0x07cd655617801ba20d8b50962e56ea07429d1126a67e3512ca2534ef95c53646;

        require(StarknetPedersen.hashPair(left, right) == expected, "four-leaf mismatch");
    }

    function testHashPairMatchesOddCountVector() external pure {
        uint256 left = 0x02cedce65ae8739f4281e152fe0efe3a524c46d7621b1154e18b1554d2991394;
        uint256 right = 0x0351bf9336fbe77f7f48eacc6967e3a72e963552f72dec940647e3339366f9a3;
        uint256 expected = 0x0340f56d221f05b76ff51dfd185c569fda5878aa2d8216a9bb5e00d369ebd11d;

        require(StarknetPedersen.hashPair(left, right) == expected, "odd-count mismatch");
    }

    function testHashPairDoesNotSortInputs() external pure {
        uint256 left = 0x015bf386477e7948a51fd27848739f156fb2bb3907e62c326d90f5f71d07e858;
        uint256 right = 0x0693e6761b37d88d77eb11e42e2fed1452bc5aa8a1566f5d5e4ec3c123e5aa04;

        uint256 sortedHash = StarknetPedersen.hashPair(left, right);
        uint256 unsortedHash = StarknetPedersen.hashPair(right, left);

        require(sortedHash != unsortedHash, "hash unexpectedly sorts");
    }

    function testHashFelt252LeafMatchesVector() external pure {
        uint256 value = 0x111111111111111111111111111111111111111111111111111111111111111;
        uint256 expected = 0x0b0ed368c332c385f755eb9d2ac5554d1c2c2692640e37d2605c0b8cfdbd78;

        require(StarknetPedersen.hashFelt252Leaf(value) == expected, "felt leaf mismatch");
    }

    function testHashPairRejectsFieldOverflow() external {
        uint256 fieldPrime =
            3618502788666131213697322783095070105623107215331596699973092056135872020481;

        (bool ok, ) = address(harness).call(
            abi.encodeCall(StarknetPedersenHarness.hashPair, (fieldPrime, 1))
        );

        require(!ok, "expected overflow revert");
    }

    function testHashFelt252LeafRejectsFieldOverflow() external {
        uint256 fieldPrime =
            3618502788666131213697322783095070105623107215331596699973092056135872020481;

        (bool ok, ) = address(harness).call(
            abi.encodeCall(StarknetPedersenHarness.hashFelt252Leaf, (fieldPrime))
        );

        require(!ok, "expected overflow revert");
    }
}
