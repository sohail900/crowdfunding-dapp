// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.22;

// import error
import "../error/ContractErrors.sol";

library CrownFundingLogic {
    enum WithdrawStatus {
        Pending,
        Requested,
        Disputed,
        Completed,
        Failed
    }
    // campaign struct
    struct Campaign {
        uint256 id;
        string ipfsHash;
        uint256 deadline;
        uint256 goal;
        uint256 raised;
        address creator;
        mapping(address => uint256) funders;
        bool active;
        WithdrawStatus withdrawStatus;
        address[] disputedBy;
        uint256 withdrawRequestedAt;
        uint256 challangePeriodEndAt;
    }

    // invalid campaign
    function invalidCampaign(
        Campaign storage campaign,
        uint256 campaignId
    ) internal view {
        if (campaign.id != campaignId) revert InvalidCampaign();
    }

    // is already sumbitted for disputer
    function alreadySumbittedForDisputer(
        Campaign storage campaign
    ) internal view {
        for (uint120 i = 0; i < campaign.disputedBy.length; i++) {
            if (campaign.disputedBy[i] == msg.sender) {
                revert AlreadySumbittedForDisputer(msg.sender);
            }
        }
    }

    // check is enough disputer
    function isEnoughDisputer(
        Campaign storage campaign
    ) internal view returns (bool) {
        if (campaign.disputedBy.length < 5) {
            return false;
        }
        return true;
    }

    // check campaign
    function validateCampaign(
        Campaign storage campaign,
        uint256 campaignId
    ) internal view {
        invalidCampaign(campaign, campaignId);
        if (!campaign.active) revert CampaignNotActive(campaignId);
        if (block.timestamp > campaign.deadline) {
            revert CampaignEnded(campaignId);
        }
    }

    // check is creator eligible to finilize withdraw
    function isCreatorEligibleToFinilizeWithdraw(
        Campaign storage campaign,
        uint256 campaignId
    ) internal view {
        invalidCampaign(campaign, campaignId);
        onlyCreator(campaign, msg.sender);
        if (campaign.withdrawStatus != WithdrawStatus.Requested)
            revert WithdrawNotRequested(campaignId);
        if (campaign.challangePeriodEndAt > block.timestamp)
            revert ChallangePeriodNotOver(campaignId);
    }

    // creator must not be a constributer
    function ensureNotCreator(
        Campaign storage campaign,
        address contributor
    ) internal view {
        if (campaign.creator == contributor) {
            revert CreatorCannotBeContributor(contributor);
        }
    }

    // check creator
    function onlyCreator(
        Campaign storage campaign,
        address creator
    ) internal view {
        if (campaign.creator != creator) revert NotCampaignCreator();
    }
}
