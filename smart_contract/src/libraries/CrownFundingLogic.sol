// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.22;

// import error
import "../error/ContractErrors.sol";

library CrownFundingLogic {
    struct Campaign {
        uint256 id;
        string ipfsHash;
        uint256 deadline;
        uint256 goal;
        uint256 raised;
        address creator;
        mapping(address => uint256) funders;
        bool active;
    }

    // check campaign
    function validateCampaign(
        Campaign storage campaign,
        uint256 campaignId
    ) internal view {
        if (campaign.id != campaignId) revert InvalidCampaign();
        if (!campaign.active) revert CampaignNotActive(campaignId);
        if (block.timestamp > campaign.deadline)
            revert CampaignEnded(campaignId);
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
