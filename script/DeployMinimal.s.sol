// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Script} from "forge-std/Script.sol";
import {MinimalAccount} from "../src/ethereum/MinimalAccount.sol";
import {Helper} from "./Helper.s.sol";

contract DeployMinimal is Script {
    function run() external {}

    function deployMinimal() public returns (Helper, MinimalAccount) {
        Helper helper = new Helper();
        Helper.NetworkConfig memory config = helper.getConfig();

        vm.startBroadcast(config.account);
        MinimalAccount minimalAccount = new MinimalAccount(config.entryPoint);
        // minimalAccount.transferOwnership(msg.sender);
        minimalAccount.transferOwnership(config.account);
        vm.stopBroadcast();

        return (helper, minimalAccount);
    }
}
