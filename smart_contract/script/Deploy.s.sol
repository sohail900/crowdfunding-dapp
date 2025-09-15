// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

import {Script} from "forge-std/Script.sol";
import {Implementation1} from "src/Implementation1.sol";
import {TransparentUpgradeableProxy} from "@openzeppelin/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";
import {ProxyAdmin} from "@openzeppelin/contracts/proxy/transparent/ProxyAdmin.sol";

contract DeployContract is Script {
    address deployer = 0x024441b7E0335b53Cd4dfCf0A1A02ed0276c2f16;

    function run() external {
        vm.startBroadcast(deployer);

        Implementation1 v1 = new Implementation1();
        ProxyAdmin admin = new ProxyAdmin(deployer);
        bytes memory initData = abi.encodeWithSelector(
            Implementation1.initialize.selector
        );
        new TransparentUpgradeableProxy(address(v1), address(admin), initData);

        vm.stopBroadcast();
    }
}
