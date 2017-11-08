pragma solidity ^0.4.16;

interface token {
    function transfer(address receiver, uint amount);
}

contract MoonFundingRound3 {
    address public beneficiary;
    uint public softCap;
    uint public amountRaised;
    uint public deadline;
    uint public price;
    token public tokenReward;
    mapping(address => uint256) public balanceOf;
    bool softCapReached = false;
    bool crowdsaleClosed = false;

    event GoalReached(address recipient, uint totalAmountRaised);
    event FundTransfer(address backer, uint amount, bool isContribution);
    
    function MoonFundingRound3
    (
        address ifSuccessfulSendTo,
        uint softCapInEthers,
        uint durationInMinutes,
        uint etherCostOfEachToken,
        address addressOfTokenUsedAsReward
    ) 
    {
        beneficiary = ifSuccessfulSendTo;
        softCap = softCapInEthers * 1 ether;
        deadline = now + durationInMinutes * 1 minutes;
        price = etherCostOfEachToken;
        tokenReward = token(addressOfTokenUsedAsReward);
    }
    
    function () payable 
    {
        require(!crowdsaleClosed);
        uint amount = msg.value;
        balanceOf[msg.sender] += amount;
        amountRaised += amount;
        tokenReward.transfer(msg.sender, amount * price);
        FundTransfer(msg.sender, amount, true);
    }

    modifier afterDeadline() { if (now >= deadline) _; }

    function checkGoalReached() afterDeadline 
    {
        if (amountRaised >= softCap)
        {
            softCapReached = true;
            GoalReached(beneficiary, amountRaised);
        }
        crowdsaleClosed = true;
    }


    //If soft cap and time limit have been reached, sends the funds to Moon Funding's wallet.
    //If soft cap has not been reached, refund users.
    function safeWithdrawal() afterDeadline 
    {
        if (!softCapReached) 
        {
            uint amount = balanceOf[msg.sender];
            balanceOf[msg.sender] = 0;
            if (amount > 0) 
            {
                if (msg.sender.send(amount)) 
                {
                    FundTransfer(msg.sender, amount, false);
                } 
                else 
                {
                    balanceOf[msg.sender] = amount;
                }
            }
        }

        if (fundingGoalReached && beneficiary == msg.sender) {
            if (beneficiary.send(amountRaised)) {
                FundTransfer(beneficiary, amountRaised, false);
            } else {
                //If we fail to send the funds to beneficiary, unlock investors balance
                fundingGoalReached = false;
            }
        }
    }
}
