// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Test} from "forge-std/Test.sol";
import {ZkMinimalAccount} from "../../src/zkSync/ZkMinimalAccount.sol";

contract TestZkMinimalAccount is Test {
    ZkMinimalAccount minimalAccount;
    function setUp() public {
        minimalAccount = new ZkMinimalAccount();
        
    }
}