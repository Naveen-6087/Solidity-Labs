// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract SimpleBank {
    mapping(address => uint256) public balances;
    address public owner;
    uint256 public totalDeposits;
    bool public isPaused;

    event Deposit(address indexed user, uint256 amount);
    event Withdraw(address indexed user, uint256 amount);
    event Paused();
    event Unpaused();

    constructor() {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Not the contract owner");
        _;
    }

    modifier whenNotPaused() {
        require(!isPaused, "Contract is paused");
        _;
    }

    // Deposit ETH
    function deposit() external payable whenNotPaused {
        require(msg.value > 0, "Cannot deposit 0 ETH");
        balances[msg.sender] += msg.value;
        totalDeposits += msg.value;
        emit Deposit(msg.sender, msg.value);
    }

    // Withdraw ETH
    function withdraw(uint256 _amount) external whenNotPaused {
        require(balances[msg.sender] >= _amount, "Insufficient balance");
        balances[msg.sender] -= _amount;
        (bool sent, ) = msg.sender.call{value: _amount}("");
        require(sent, "Failed to send ETH");
        emit Withdraw(msg.sender, _amount);
    }
    // View balance
    function getBalance() external view returns (uint256) {
        return balances[msg.sender];
    }

    // Admin: Pause the contract
    function pause() external onlyOwner {
        isPaused = true;
        emit Paused();
    }

    // Admin: Unpause the contract
    function unpause() external onlyOwner {
        isPaused = false;
        emit Unpaused();
    }

    // Admin: Emergency withdraw (in case funds get stuck)
    function emergencyWithdraw() external onlyOwner {
        (bool sent, ) = owner.call{value: address(this).balance}("");
        require(sent, "Emergency withdraw failed");
    }
    // Fallback to reject accidental ETH
    fallback() external payable {
        revert("Use deposit function");
    }
    receive() external payable {
        revert("Use deposit function");
    }
}
