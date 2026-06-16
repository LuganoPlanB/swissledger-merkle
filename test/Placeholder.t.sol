// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import {BuildInfo} from "../src/generated/BuildInfo.sol";
import {Placeholder} from "../src/Placeholder.sol";

contract PlaceholderTest {
    function testVersion() external {
        Placeholder placeholder = new Placeholder();
        require(
            keccak256(bytes(placeholder.version())) == keccak256(bytes(BuildInfo.VERSION)),
            "unexpected version"
        );
    }
}
