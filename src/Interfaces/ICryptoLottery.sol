// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

interface IERC20 {
  function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
  function transfer(address recipient, uint256 amount) external returns (bool);
  function balanceOf(address account) external view returns (uint256);
}

enum Phase {
  start,
  winnerDrawed
}

error callerNotOwner();
error numberTicketZero();
error transferFailed();
error minimumPlayersNotReach();
error minimumPlayersMustGreaterThan2();
error noWinner();
error drawTimeNotfinish();
// error drawPaused();
error royaltiesExceedTenPercent();