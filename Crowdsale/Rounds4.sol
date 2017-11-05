pragma solidity ^0.4.16;

interface token {
    function transfer(address receiver, uint amount);
}

contract MoonFundingRound4 {
    address public beneficiary;
    uint public fundingGoal;
    uint public amountRaised;
    uint public deadline;
    uint public price;
    token public tokenReward;
    mapping(address => uint256) public balanceOf;
    bool fundingGoalReached = false;
    bool crowdsaleClosed = false;

    event GoalReached(address recipient, uint totalAmountRaised);
    event FundTransfer(address backer, uint amount, bool isContribution);

    /**
     * Constrctor function
     *
     * Setup the owner
     */
    function MoonFundingRound4
    (
        address ifSuccessfulSendTo,
        uint fundingGoalInEthers,
        uint durationInMinutes,
        uint etherCostOfEachToken,
        address addressOfTokenUsedAsReward
    ) 
    {
        beneficiary = ifSuccessfulSendTo;
        fundingGoal = fundingGoalInEthers;
        deadline = now + durationInMinutes * 1 minutes;
        price = etherCostOfEachToken;
        tokenReward = token(addressOfTokenUsedAsReward);
    }
    
    function () payable {
        require(!crowdsaleClosed);
        uint amount = msg.value;
        balanceOf[msg.sender] += amount;
        amountRaised += amount;
        tokenReward.transfer(msg.sender, amount * price);
        FundTransfer(msg.sender, amount, true);
    }

    modifier afterDeadline() { if (now >= deadline) _; }

    
     
    //Checks if the goal or time limit has been reached and ends the campaign
    function checkGoalReached() afterDeadline 
    {
        if (amountRaised >= fundingGoal)
        {
            fundingGoalReached = true;
            GoalReached(beneficiary, amountRaised);
        }
        crowdsaleClosed = true;
    }


    //After time limit has been reached, send the entire amount to MoonFunding's wallet
    function safeWithdrawal() afterDeadline {

        if (beneficiary == msg.sender) 
        { 
            if (beneficiary.send(amountRaised)) 
            {
                FundTransfer(beneficiary, amountRaised, false);
            } 
        }
    }
}
