// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "@openzeppelin/contracts/access/Ownable.sol";

contract MonatardioFaucet is Ownable{
    uint256 public withdrawalAmount = 0.2 * 10**18;
    uint256 public cooldownPeriod = 24 hours;
    
    mapping(address => uint256) private lastWithdrawalTime;
    
    event Withdraw(address indexed receiver, uint256 amount);
    event OwnerWithdraw(uint256 amount);

    constructor() Ownable(msg.sender) {}

    function withdraw(address payable to) external onlyOwner {
        require(
            block.timestamp >= lastWithdrawalTime[to] + cooldownPeriod,
            "Claim available once per day"
        );
        require(
            address(this).balance >= withdrawalAmount,
            "Not enough MON in contract"
        );
        require(to != address(0), "Invalid address");

        lastWithdrawalTime[to] = block.timestamp;
        (bool sent,) = to.call{value: withdrawalAmount}("");
        require(sent, "Failed to send MON");
        emit Withdraw(to, withdrawalAmount);
    }

    receive() external payable {}

    function withdrawOwner() external onlyOwner {
        uint256 amount = address(this).balance;
        (bool sent,) = owner().call{value: amount}("");
        require(sent, "Failed to send MON");
        emit OwnerWithdraw(amount);
    }

    function setWithdrawalAmount(uint256 newAmount) external onlyOwner {
        withdrawalAmount = newAmount;
    }

    function setCooldownPeriod(uint256 newPeriod) external onlyOwner {
        cooldownPeriod = newPeriod;
    }

    function getBalance() external view returns (uint256) {
        return address(this).balance;
    }

    function getNextAvailableTime(address user) external view returns (uint256) {
        return lastWithdrawalTime[user] + cooldownPeriod;
    }
}