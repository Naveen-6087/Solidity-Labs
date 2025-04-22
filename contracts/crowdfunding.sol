// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

contract Crowdfunding {
    uint public campaignCount;

    struct Campaign {
        address payable owner;
        uint goal;
        uint deadline;
        uint raisedAmount;
        bool goalReached;
        bool fundsWithdrawn;
    }

    mapping(uint => Campaign) public campaigns;
    mapping(uint => mapping(address => uint)) public contributions;

    // Events
    event CampaignCreated(uint id, address owner, uint goal, uint deadline);
    event ContributionReceived(uint campaignId, address contributor, uint amount);
    event GoalReached(uint campaignId, uint totalAmount);
    event FundsWithdrawn(uint campaignId, uint amount);
    event RefundClaimed(uint campaignId, address contributor, uint amount);

    // Modifiers
    modifier onlyOwner(uint campaignId) {
        require(msg.sender == campaigns[campaignId].owner, "Not campaign owner");
        _;
    }

    modifier onlyBeforeDeadline(uint campaignId) {
        require(block.timestamp < campaigns[campaignId].deadline, "Deadline passed");
        _;
    }

    modifier onlyAfterDeadline(uint campaignId) {
        require(block.timestamp >= campaigns[campaignId].deadline, "Deadline not reached");
        _;
    }

    // Create a new campaign
    function createCampaign(uint _goal, uint _durationInDays) external {
        require(_goal > 0, "Goal must be positive");
        uint deadline = block.timestamp + (_durationInDays * 1 days);
        campaigns[campaignCount] = Campaign({
            owner: payable(msg.sender),
            goal: _goal,
            deadline: deadline,
            raisedAmount: 0,
            goalReached: false,
            fundsWithdrawn: false
        });
        emit CampaignCreated(campaignCount, msg.sender, _goal, deadline);
        campaignCount++;
    }

    // Contribute to a campaign
    function contribute(uint campaignId) external payable onlyBeforeDeadline(campaignId) {
        require(msg.value > 0, "Contribution must be greater than 0");
        Campaign storage camp = campaigns[campaignId];
        camp.raisedAmount += msg.value;
        contributions[campaignId][msg.sender] += msg.value;
        emit ContributionReceived(campaignId, msg.sender, msg.value);
        if (!camp.goalReached && camp.raisedAmount >= camp.goal) {
            camp.goalReached = true;
            emit GoalReached(campaignId, camp.raisedAmount);
        }
    }

    // Withdraw funds (by campaign owner)
    function withdrawFunds(uint campaignId) external onlyOwner(campaignId) onlyAfterDeadline(campaignId) {
        Campaign storage c = campaigns[campaignId];
        require(c.goalReached, "Goal not reached");
        require(!c.fundsWithdrawn, "Funds already withdrawn");
        c.fundsWithdrawn = true;
        c.owner.transfer(c.raisedAmount);
        emit FundsWithdrawn(campaignId, c.raisedAmount);
    }
    // Claim refund (by contributor)
    function claimRefund(uint campaignId) external onlyAfterDeadline(campaignId) {
        Campaign storage c = campaigns[campaignId];
        require(!c.goalReached, "Goal was reached");

        uint contributed = contributions[campaignId][msg.sender];
        require(contributed > 0, "No contributions to refund");

        contributions[campaignId][msg.sender] = 0;
        payable(msg.sender).transfer(contributed);

        emit RefundClaimed(campaignId, msg.sender, contributed);
    }
    // View campaign details
    function getCampaignDetails(uint campaignId) external view returns (
        address owner,
        uint goal,
        uint deadline,
        uint raisedAmount,
        bool goalReached,
        bool fundsWithdrawn
    ) {
        Campaign memory c = campaigns[campaignId];
        return (
            c.owner,
            c.goal,
            c.deadline,
            c.raisedAmount,
            c.goalReached,
            c.fundsWithdrawn
        );
    }
    // View user's contribution to a campaign
    function getContribution(uint campaignId, address contributor) external view returns (uint) {
        return contributions[campaignId][contributor];
    }
}
