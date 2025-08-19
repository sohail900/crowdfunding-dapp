// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "src/Contract.sol";

contract TestContract is Test {
    Contract c;
    address owner;

    function setUp() public {
        c = new Contract(0x9f635fB9305d0A8ecaf6108F0c14b1464dBdC7fe);
    }

    function testBar() public {
        assertEq(uint256(1), uint256(1), "ok");
    }

    function testFoo(uint256 x) public {
        vm.assume(x < type(uint128).max);
        assertEq(x + x, x * 2);
    }
}
