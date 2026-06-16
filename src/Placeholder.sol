// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import {BuildInfo} from "./generated/BuildInfo.sol";

contract Placeholder {
    function version() external pure returns (string memory) {
        return BuildInfo.VERSION;
    }
}
