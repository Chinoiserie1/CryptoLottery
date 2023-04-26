// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "../src/CryptoLottery.sol";

contract CounterTest is Test {
    CryptoLottery public coucryptoLottery;

    function setUp() public {
        coucryptoLottery = new CryptoLottery();
    }

    
}
