// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import {Placeholder} from "../src/Placeholder.sol";

contract PlaceholderTest {
    function testVersion() external {
        Placeholder placeholder = new Placeholder();
        require(
            keccak256(bytes(placeholder.version())) == keccak256(bytes("solidity-merkle-verifier")),
            "unexpected version"
        );
    }
}
