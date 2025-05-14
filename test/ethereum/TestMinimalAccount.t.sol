// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Test} from "forge-std/Test.sol";
import {MinimalAccount} from "../../src/ethereum/MinimalAccount.sol";
import {DeployMinimal} from "../../script/DeployMinimal.s.sol";
import {Helper} from "../../script/Helper.s.sol";
import {ERC20Mock} from "@openzeppelin/contracts/mocks/token/ERC20Mock.sol";
import {SendPackedUserOps, PackedUserOperation} from "../../script/SendPackedUserOp.s.sol";
import {ECDSA} from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import {IEntryPoint} from "lib/account-abstraction/contracts/interfaces/IEntryPoint.sol";
import {MessageHashUtils} from "@openzeppelin/contracts/utils/cryptography/MessageHashUtils.sol";

contract TestMinimalAccount is Test {
    using MessageHashUtils for bytes32;

    error MinimalAccount__NotFromEntryOpintOrOwner();

    Helper helper;
    MinimalAccount minimalAccount;
    SendPackedUserOps userOp;
    ERC20Mock usdc;
    address user = makeAddr("user");

    uint256 constant AMOUNT = 1e18;

    function setUp() public {
        DeployMinimal deployer = new DeployMinimal();
        (helper, minimalAccount) = deployer.deployMinimal();
        usdc = new ERC20Mock();
        userOp = new SendPackedUserOps();
    }

    // USDC mint
    // msg.sender -> Minimal Account
    // Approve some amount
    // USDC contract
    // Come from the entry point.
    function testOwnerCanExecutesCommand() public {
        assertEq(usdc.balanceOf(address(minimalAccount)), 0);

        address dest = address(usdc);
        uint256 value = 0;
        bytes memory functionData = abi.encodeWithSelector(ERC20Mock.mint.selector, address(minimalAccount), AMOUNT);

        vm.prank(minimalAccount.owner());
        minimalAccount.execute(dest, value, functionData);

        assertEq(usdc.balanceOf(address(minimalAccount)), AMOUNT);
    }

    function testNonOwnerCannotExecutesCommand() public {
        assertEq(usdc.balanceOf(address(minimalAccount)), 0);

        address dest = address(usdc);
        uint256 value = 0;
        bytes memory functionData = abi.encodeWithSelector(ERC20Mock.mint.selector, address(minimalAccount), AMOUNT);

        vm.prank(user);
        vm.expectRevert(MinimalAccount.MinimalAccount__NotFromEntryOpintOrOwner.selector);
        minimalAccount.execute(dest, value, functionData);
    }

    function testRecoverSignedOp() public {
        assertEq(usdc.balanceOf(address(minimalAccount)), 0);

        address dest = address(usdc);
        uint256 value = 0;
        bytes memory functionData = abi.encodeWithSelector(ERC20Mock.mint.selector, address(minimalAccount), AMOUNT);
        bytes memory executeCalldata =
            abi.encodeWithSelector(MinimalAccount.execute.selector, dest, value, functionData);
        PackedUserOperation memory packedUserOp =
            userOp.generatedSignedUserOps(executeCalldata, helper.getConfig(), address(minimalAccount));

        bytes32 userOperationHash = IEntryPoint(helper.getConfig().entryPoint).getUserOpHash(packedUserOp);
        address signer = ECDSA.recover(userOperationHash.toEthSignedMessageHash(), packedUserOp.signature);

        assertEq(signer, minimalAccount.owner());
    }

    function testValidationOfUserOps() public {
        assertEq(usdc.balanceOf(address(minimalAccount)), 0);

        address dest = address(usdc);
        uint256 value = 0;
        bytes memory functionData = abi.encodeWithSelector(ERC20Mock.mint.selector, address(minimalAccount), AMOUNT);
        bytes memory executeCalldata =
            abi.encodeWithSelector(MinimalAccount.execute.selector, dest, value, functionData);
        PackedUserOperation memory packedUserOp =
            userOp.generatedSignedUserOps(executeCalldata, helper.getConfig(), address(minimalAccount));

        bytes32 userOperationHash = IEntryPoint(helper.getConfig().entryPoint).getUserOpHash(packedUserOp);
        uint256 missingAccountFunds = 1e18;

        vm.prank(helper.getConfig().entryPoint);
        uint256 validationData = minimalAccount.validateUserOp(packedUserOp, userOperationHash, missingAccountFunds);

        assertEq(validationData, 0); // 0 meanse it is verified.
    }

    function testEntryPointCanExecuteCommands() public {
        assertEq(usdc.balanceOf(address(minimalAccount)), 0);

        address dest = address(usdc);
        uint256 value = 0;
        bytes memory functionData = abi.encodeWithSelector(ERC20Mock.mint.selector, address(minimalAccount), AMOUNT);
        bytes memory executeCalldata =
            abi.encodeWithSelector(MinimalAccount.execute.selector, dest, value, functionData);
        PackedUserOperation memory packedUserOp =
            userOp.generatedSignedUserOps(executeCalldata, helper.getConfig(), address(minimalAccount));

        // bytes32 userOperationHash = IEntryPoint(helper.getConfig().entryPoint).getUserOpHash(packedUserOp);
        vm.deal(address(minimalAccount), 1e18);
        PackedUserOperation[] memory ops = new PackedUserOperation[](1);
        ops[0] = packedUserOp;
        vm.prank(user);
        IEntryPoint(helper.getConfig().entryPoint).handleOps(ops, payable(user));
        assertEq(usdc.balanceOf(address(minimalAccount)), AMOUNT);
    }
}
