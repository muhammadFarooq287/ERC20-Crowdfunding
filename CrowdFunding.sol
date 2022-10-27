// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.7;

interface IERC20
{
    function transfer(
        address,
        uint)
        external
        returns(bool);

    function transferFrom(
        address,
        address,
        uint)
        external
        returns(bool);
}

/** 
* @title CrowdFunding Smart Contract
* @author Muhammad Farooq BLK Cohort-3
* Date: 27 October 2022
*/

contract CrowdFund {

    // Error Messages for the contract
    error ErrorStartTimeIsLessThanBlockTimestamp(uint256 blockTimestmap, uint256 startTime);
    error ErrorEndTimeIsLessThanStartTime(uint startTime, uint endTime);
    error ErrorEndTimeExceedsMaximumDuration(uint256 maxDuration, uint256 endTime);
    error ErrorYouAreNotCreator(address creator);
    error ErrorCampaignAlreadyStarted( uint blocktimestamp, uint startTime);
    error ErrorCampaignAlreadyEnded( uint blocktimestamp, uint endTime );
    error ErrorCampaignNotStarted( uint blocktimestamp, uint startTime );
    error ErrorCampaignNotEnded( uint blocktimestamp, uint endTime );
    error ErrorNotEnoughTokensPledgedToWithraw(uint tokens);
    error ErrorCampaignNotSucceded( uint campaignGoal, uint pledgedAmount );
    error ErrorCannotWithdrawCampaignSucceded( uint campaignGoal, uint pledgedAmount );
    error ErrorCampaignAlreadyClaimed( uint id);
    
    struct Campaign {
        address creator;
        uint goal;
        uint pledged;
        uint startAt;
        uint endAt;
        bool claimed;
    }

    IERC20 public immutable token;
    uint public totalCampaigns;
    uint public maxDuration;
    mapping(uint => Campaign) public campaigns;
    mapping(uint => mapping(address => uint)) public pledgedAmount;

    event campaignCreated(
        uint id,
        address indexed creator,
        uint goal,
        uint32 startAt,
        uint32 endAt
    );
    event Cancel(uint id);
    event Pledge(uint indexed id, address indexed caller, uint amount);
    event Unpledge(uint indexed id, address indexed caller, uint amount);
    event Claim(uint id);
    event Refund(uint id, address indexed caller, uint amount);

    /** 
    * @dev Deploy your Contract with ERC20 token 
    * @param _token Address of ERC20 Contract, _maxDuration maximum duration till Campaigns can be created
    */

    constructor(
        address _token,
        uint _maxDuration)
    {
        token = IERC20(_token);
        maxDuration = _maxDuration;
    }

    /** 
    * @dev It creates New campaign
    * @param _goal number of tokens you want to collect, _startAt start Time, _endAt end Time  
    */

    function createCampaign(
        uint _goal,
        uint32 _startAt,
        uint32 _endAt)
        external
    {
        if (_startAt < block.timestamp)
        {
            revert ErrorStartTimeIsLessThanBlockTimestamp(block.timestamp, _startAt);
        }

        if (_endAt < _startAt)
        {
            revert ErrorEndTimeIsLessThanStartTime(_startAt, _endAt);
        }

        if (_endAt > block.timestamp + maxDuration)
        {
            revert ErrorEndTimeExceedsMaximumDuration(block.timestamp + maxDuration, _endAt);
        }

        totalCampaigns += 1;
        campaigns[totalCampaigns] = Campaign({
            creator: msg.sender,
            goal: _goal,
            pledged: 0,
            startAt: _startAt,
            endAt: _endAt,
            claimed: false
        });

        emit campaignCreated(totalCampaigns,msg.sender,_goal,_startAt,_endAt);
    }

    /** 
    * @dev It allows the campaign's creator to end the campaign 
    * @param _id of the Campaign 
    */

    function cancel(
        uint _id)
        external
    {
        Campaign memory campaign = campaigns[_id];

        if (campaign.creator != msg.sender)
        {
            revert ErrorYouAreNotCreator( campaign.creator );
        }

        if (block.timestamp > campaign.startAt)
        {
            revert ErrorCampaignAlreadyStarted( block.timestamp, campaign.startAt );
        }

        delete campaigns[_id];
        emit Cancel(_id);
    }

    /** 
    * @dev It transfers the tokens that a user has want to pledge, tokens
    *      are transferred to contract.
    * @param _id of the Campaign, _amount want to pledge
    */

    function pledge(
        uint _id,
        uint _amount)
        external
    {
        Campaign storage campaign = campaigns[_id];

        if (block.timestamp < campaign.startAt)
        {
            revert ErrorCampaignNotStarted( block.timestamp, campaign.startAt );
        }
        
        if (block.timestamp > campaign.endAt)
        {
            revert ErrorCampaignAlreadyEnded( block.timestamp, campaign.endAt );
        }
        
        campaign.pledged += _amount;
        pledgedAmount[_id][msg.sender] += _amount;
        token.transferFrom(msg.sender, address(this), _amount);

        emit Pledge(_id, msg.sender, _amount);
    }

    /** 
    * @dev It removes the tokens that a user has pledged, just as the pledge function.
    * @param _id of the Campaign, _amount you want to unpledge 
    */

    function unPledge(
        uint _id,
        uint _amount)
        external
    {
        Campaign storage campaign = campaigns[_id];

        if (block.timestamp < campaign.startAt)
        {
            revert ErrorCampaignNotStarted( block.timestamp, campaign.startAt );
        }

        if (block.timestamp > campaign.endAt)
        {
            revert ErrorCampaignAlreadyEnded( block.timestamp, campaign.endAt );
        }

        if (pledgedAmount[_id][msg.sender] < _amount)
        {
            revert ErrorNotEnoughTokensPledgedToWithraw(pledgedAmount[_id][msg.sender]);
        }

        campaign.pledged -= _amount;
        pledgedAmount[_id][msg.sender] -= _amount;
        token.transfer(msg.sender, _amount);

        emit Unpledge(_id, msg.sender, _amount);
    }

    /** 
    * @dev The creator can claim all of the tokens raised for the campaign with the help of a claim function 
    * @param _id of the Campaign 
    */
    function claim(
        uint _id)
        external
    {
        Campaign storage campaign = campaigns[_id];

        if (campaign.creator != msg.sender)
        {
            revert ErrorYouAreNotCreator( campaign.creator );
        }

        if (block.timestamp < campaign.endAt)
        {
            revert ErrorCampaignNotEnded( block.timestamp, campaign.endAt );
        }

        if (campaign.pledged < campaign.goal)
        {
            revert ErrorCampaignNotSucceded( campaign.goal, campaign.pledged );
        }

        if (campaign.claimed)
        {
            revert ErrorCampaignAlreadyClaimed( _id);
        }

        campaign.claimed = true;
        token.transfer(campaign.creator, campaign.pledged);

        emit Claim(_id);
    }

    /** 
    * @dev When the campaign is unsuccessful, we create a refund function that allows users to withdraw their tokens from the contract.
    * @param _id of the Campaign 
    */

    function refund(
        uint _id)
        external
    {
        Campaign memory campaign = campaigns[_id];

        if (block.timestamp < campaign.endAt)
        {
            revert ErrorCampaignNotEnded( block.timestamp, campaign.endAt );
        }
        
        if (campaign.pledged >= campaign.goal)
        {
            revert ErrorCannotWithdrawCampaignSucceded( campaign.goal,  campaign.pledged );
        }

        uint bal = pledgedAmount[_id][msg.sender];
        pledgedAmount[_id][msg.sender] = 0;
        token.transfer(msg.sender, bal);

        emit Refund(_id, msg.sender, bal);
    }

}
