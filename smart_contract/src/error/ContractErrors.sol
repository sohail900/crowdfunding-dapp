// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.22;

error CampaignNotActive(uint256 campaignId);
error CampaignEnded(uint256 campaignId);
error InvalidCampaign();
error DeadlineMustBeInTheFuture();
error GoalMustBeGreaterThanZero();
error CampaignDetailsMustRequired();
error GoalNotMeetYet(uint256 campaignId);
error TransferFailed(uint256 campaignId, address creator);
error MustBeAFunderToRefund(address funder);
// for creators
error NotCampaignCreator();
error CreatorCannotBeContributor(address _creator);
