# ERC20-Crowdfunding
Crowdfunding is the practice of using modest sums of money from a large number of people to finance a new business endeavor. 
Let's say I want to open a modest tea shop, but I lack the resources or cash to do so. What then can I do?
Either I can get a loan from a friend, my family, or the bank, or I may ask someone to give me money and work with me on a project. Crowdfunding will be used if the project is too large for a single investor to invest in. I will solicit money from anyone in exchange for shares of my business, and each investment will possess a part in the business.
The business owner calls the contract to launch a campaign using several justifications, including the number of tokens that must be raised for the campaign, its start timestamp, and its end timestamp.
As long as the campaign has not already begun, the business owner may cancel it at any time.
By using the "pledge" function and entering the "id" of the campaign along with the number of tokens to be pledged, users can donate their tokens to a particular campaign.
As long as the campaign is still active, they can also withdraw their previously pledged tokens.
After the campaign is over, one of the two possible results is -
A campaign is considered successful when it raises the required number of tokens and meets the business owner's minimum requirements. In this scenario, the business owner can call the "claim" function to withdraw all the tokens.
If not enough tokens are pledged, which is the other scenario where a campaign fails, pledgers can withdraw their tokens from the contract by using the "withdraw" function.


First function, "CreateCampaign" which accepts the campaign's goal, the start timestamp, and the end timestamp, is now defined.

Before starting the campaign, we first perform some checks.
We determine whether the commencement time exceeds the current time.
We make sure the end time is later than the beginning time.
Finally, we make sure the campaign does not go beyond its maximum time.

Next, we define a function called cancel, which allows the campaign's creator to end the campaign provided that they are the campaign's creator and that the campaign has not yet begun.

We have now developed our pledge feature, which asks for the campaign id and the number of tokens that need to be pledged.

In order to transfer tokens from the user to the smart contract, we first run basic tests, such as determining whether the campaign has begun or concluded. Next, we use the token variable, which corresponds to the IERC interface and call the transferFrom function to transfer tokens from the user to the smart contract.

By increasing the amount of tokens offered by the campaign and storing the number of tokens pledged by the user, we modify the state variables of the contract.

And then we emit the Pledge event.

We provide a function called unpledge that removes the tokens that a user has pledged, just as the pledge function.

The creator can claim all of the tokens raised for the campaign with the help of a claim function that we define next if the following criteria are met.

the campaign's originator is the one who called the function.
The campaign has come to a close.
The objective has been surpassed by the quantity of tokens raised (campaign succeded)
The tokens have not yet been redeemed.

In the event that the campaign is unsuccessful, we create a refund function that allows users to withdraw their tokens from the contract.
