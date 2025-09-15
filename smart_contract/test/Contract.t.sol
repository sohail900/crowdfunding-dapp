// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.13;

import {Test} from "forge-std/Test.sol";
import {console2} from "forge-std/console2.sol";
import {Implementation1} from "src/Implementation1.sol";
import {TransparentUpgradeableProxy} from "@openzeppelin/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";

contract TestContract is Test {
    Implementation1 v1;
    TransparentUpgradeableProxy proxy;
    Implementation1 proxyAsV1;
    // address
    address admin = 0x9f635fB9305d0A8ecaf6108F0c14b1464dBdC7fe;
    address _user = 0x1dF536e264Db04bD84089959B2A430fE041Ba1AE;

    // setup
    function setUp() public {
        v1 = new Implementation1();
        bytes memory initData = abi.encodeWithSelector(
            Implementation1.initialize.selector
        );
        proxy = new TransparentUpgradeableProxy(address(v1), admin, initData);
        proxyAsV1 = Implementation1(address(proxy));
    }

    receive() external payable {}

    // test initilizer
    function testInitilizer() public view {
        assertEq(proxyAsV1.campaignCount(), 0, "Initial campaigns should be 0");
    }

    // test create campaigs
    function testCampaigns() public {
        proxyAsV1.createCampaign("hello", 1 ether, 5 days);
        assertEq(proxyAsV1.campaignCount(), 1, "Total campaign should be 1");
        (, , uint256 deadline, uint256 goal, , , ) = proxyAsV1.campaigns(1);
        assertEq(goal, 1 ether, "it should be 1 ether");
        assertEq(deadline, block.timestamp + 5 days, "it should be 5 days");
    }

    // test constribute
    function testConstribute() public {
        proxyAsV1.createCampaign("constribute", 2 ether, 7 days);
        proxyAsV1.constribute{value: 1 ether}(1);
        (, , , , uint256 raised, , ) = proxyAsV1.campaigns(1);
        assertEq(raised, 1 ether, "it should be 1 ether");
        assertEq(proxyAsV1.getFunder(1), 1 ether, "not the user");
        vm.deal(_user, 3 ether);
        vm.startPrank(_user);
        proxyAsV1.constribute{value: 1 ether}(1);
        (, , , , uint256 updatedRaised, , ) = proxyAsV1.campaigns(1);
        console2.logUint(updatedRaised);
        assertEq(updatedRaised, 2 ether, "it should be around 1.8 ether");
        assertEq(proxyAsV1.getFunder(1), 1 ether, "2 invalid user");
        vm.stopPrank();
    }

    // test withdraw
    function testWithdraw() public {
        vm.deal(_user, 2 ether);
        vm.prank(_user);
        proxyAsV1.createCampaign("new", 1 ether, 1 days);
        proxyAsV1.constribute{value: 1 ether}(1);
        vm.startPrank(_user);
        proxyAsV1.withdrawFunds(1);
        assertEq(address(_user).balance, 3 ether, "failed retry");
        vm.stopPrank();
    }

    // refund withdraw
    function testRefund() public {
        proxyAsV1.createCampaign("refund test", 2 ether, 1 days);
        vm.deal(_user, 4 ether);
        vm.startPrank(_user);
        proxyAsV1.constribute{value: 1 ether}(1);
        proxyAsV1.refund(1);
        assertEq(address(_user).balance, 4 ether, "it's not be 4 ether");
        vm.stopPrank();
    }

    //  test extend deadline
    function testExtendDeadline() public {
        proxyAsV1.createCampaign("test deadline", 1 ether, 1 days);
        vm.expectEmit(true, false, false, true);
        emit Implementation1.CampaignExtended(1, address(this));
        proxyAsV1.extendDeadline(1, 2 days);
        (, , uint256 deadline, , , , ) = proxyAsV1.campaigns(1);
        assertEq(deadline, block.timestamp + 2 days, "it should be 2 days");
    }
}
