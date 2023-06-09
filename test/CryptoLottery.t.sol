// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import { TestERC20 } from "./token/TestERC20.sol";
import { CryptoLottery } from "../src/CryptoLottery.sol";

// import "../src/Interfaces/ICryptoLottery.sol";
import "lib/openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";

import "forge-std/Test.sol";

error callerNotOwner();
error numberTicketZero();
error transferFailed();
error minimumPlayersNotReach();
error minimumPlayersMustGreaterThan2();
error noWinner();
error drawTimeNotfinish();
error royaltiesExceedTenPercent();

contract CryptoLotteryTest is Test {
  CryptoLottery public cryptoLottery;
  TestERC20 public testERC20;

  uint256 internal ownerPrivateKey;
  address internal owner;
  uint256 internal user1PrivateKey;
  address internal user1;
  uint256 internal user2PrivateKey;
  address internal user2;
  uint256 internal user3PrivateKey;
  address internal user3;
  uint256 internal royaltiesPrivateKey;
  address internal royaltiesAddress;

  uint256 ticketPrice = 10000;

  function setUp() public {
    ownerPrivateKey = 0xA11CE;
    owner = vm.addr(ownerPrivateKey);
    user1PrivateKey = 0xB0B;
    user1 = vm.addr(user1PrivateKey);
    user2PrivateKey = 0xFED;
    user2 = vm.addr(user2PrivateKey);
    user3PrivateKey = 0xAD1;
    user3 = vm.addr(user3PrivateKey);
    royaltiesPrivateKey = 0xD0E;
    royaltiesAddress = vm.addr(royaltiesPrivateKey);
    vm.startPrank(owner);

    cryptoLottery = new CryptoLottery();
    testERC20 = new TestERC20();
    cryptoLottery.setTokenAddress(address(testERC20));
    cryptoLottery.setTicketPrice(ticketPrice);
    cryptoLottery.setRoyaltiesAddress(royaltiesAddress);
    IERC20(address(testERC20)).transfer(user1, 10 ether);
    IERC20(address(testERC20)).transfer(user2, 10 ether);
    IERC20(address(testERC20)).transfer(user3, 10 ether);
  }

  function testVariablesAfterDeployement() public view {
    require(cryptoLottery.owner() == owner, "fail set owner");
    require(cryptoLottery.winner() == address(0), "fail set winner");
    require(cryptoLottery.royaltiesAddress() == royaltiesAddress, "fail set royalties address");
    require(cryptoLottery.ticketPrice() == ticketPrice, "fail set ticket price");
  }

  function testBuyTickets() public {
    vm.stopPrank();
    vm.startPrank(user1);
    require(cryptoLottery.getPlayers().length == 0, "players not set correctly");
    IERC20(address(testERC20)).approve(address(cryptoLottery), ticketPrice);
    cryptoLottery.buyTickets(1);
    require(cryptoLottery.getPlayers().length == 1, "players not set correctly after buy");
    require(
      IERC20(address(testERC20)).balanceOf(address(cryptoLottery)) == ticketPrice,
      "transfer erc20 failed"
    );
  }

  function testGetWinner() public {
    vm.stopPrank();
    vm.startPrank(user1);
    require(cryptoLottery.getPlayers().length == 0, "players not set correctly");
    IERC20(address(testERC20)).approve(address(cryptoLottery), ticketPrice);
    cryptoLottery.buyTickets(1);
    vm.stopPrank();
    vm.startPrank(user2);
    IERC20(address(testERC20)).approve(address(cryptoLottery), ticketPrice);
    cryptoLottery.buyTickets(1);
    require(
      IERC20(address(testERC20)).balanceOf(address(cryptoLottery)) == ticketPrice * 2,
      "transfer erc20 failed"
    );
    vm.stopPrank();
    vm.startPrank(owner);
    uint256 lastDrawTimestamp = cryptoLottery.lastDrawTime();
    vm.warp(lastDrawTimestamp + 1 hours);
    cryptoLottery.getWinner();
  }

  function testDraw() public {
    vm.stopPrank();
    vm.startPrank(user1);
    require(cryptoLottery.getPlayers().length == 0, "players not set correctly");
    IERC20(address(testERC20)).approve(address(cryptoLottery), ticketPrice);
    cryptoLottery.buyTickets(1);
    vm.stopPrank();
    vm.startPrank(user2);
    IERC20(address(testERC20)).approve(address(cryptoLottery), ticketPrice);
    cryptoLottery.buyTickets(1);
    require(
      IERC20(address(testERC20)).balanceOf(address(cryptoLottery)) == ticketPrice * 2,
      "transfer erc20 failed"
    );
    vm.stopPrank();
    vm.startPrank(owner);
    uint256 lastDrawTimestamp = cryptoLottery.lastDrawTime();
    vm.warp(lastDrawTimestamp + 1 hours);
    address winner = cryptoLottery.getWinner();
    uint256 prizePool = cryptoLottery.getPrizePool();
    uint256 balanceWinnerBefore = IERC20(address(testERC20)).balanceOf(winner);
    cryptoLottery.distributePrize();
    uint256 balanceWinnerAfter = IERC20(address(testERC20)).balanceOf(winner);
    require(balanceWinnerAfter == balanceWinnerBefore + prizePool, "fail trasnfer amount to winner");
  }

  function testDrawRestartCorrectlyWithFirstBidder() public {
    vm.stopPrank();
    vm.startPrank(user1);
    require(cryptoLottery.getPlayers().length == 0, "players not set correctly");
    IERC20(address(testERC20)).approve(address(cryptoLottery), ticketPrice);
    cryptoLottery.buyTickets(1);
    vm.stopPrank();
    vm.startPrank(user2);
    IERC20(address(testERC20)).approve(address(cryptoLottery), ticketPrice);
    cryptoLottery.buyTickets(1);
    require(
      IERC20(address(testERC20)).balanceOf(address(cryptoLottery)) == ticketPrice * 2,
      "transfer erc20 failed"
    );
    vm.stopPrank();
    vm.startPrank(owner);
    uint256 lastDrawTimestamp = cryptoLottery.lastDrawTime();
    vm.warp(lastDrawTimestamp + 1 hours);
    address winner = cryptoLottery.getWinner();
    uint256 prizePool = cryptoLottery.getPrizePool();
    uint256 balanceWinnerBefore = IERC20(address(testERC20)).balanceOf(winner);
    vm.stopPrank();
    vm.startPrank(user3);
    IERC20(address(testERC20)).approve(address(cryptoLottery), ticketPrice);
    cryptoLottery.buyTickets(1);
    uint256 balanceWinnerAfter = IERC20(address(testERC20)).balanceOf(winner);
    require(balanceWinnerAfter == balanceWinnerBefore + prizePool, "fail trasnfer amount to winner");
    prizePool = cryptoLottery.getPrizePool();
  }

  function testOnlyOwner() public {
    vm.stopPrank();
    vm.startPrank(user1);
    vm.expectRevert(callerNotOwner.selector);
    cryptoLottery.setTicketPrice(100);
    vm.expectRevert(callerNotOwner.selector);
    cryptoLottery.setMinimumPlayers(3);
    vm.expectRevert(callerNotOwner.selector);
    cryptoLottery.setMinimumDrawTime(2 hours);
    vm.expectRevert(callerNotOwner.selector);
    cryptoLottery.setRoyaltiesAddress(user1);
    vm.expectRevert(callerNotOwner.selector);
    cryptoLottery.setRoyaltiesPercent(0);
    vm.expectRevert(callerNotOwner.selector);
    cryptoLottery.setTokenAddress(address(0));
  }
}
