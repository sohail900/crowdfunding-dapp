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
error WithdrawNotRequested(uint256 campaignId);
error ChallangePeriodNotOver(uint256 campaignId);
error WithdrawRequestNotPending(uint256 campaignId);
error WithdrawIsDisputed(uint256 campaignId);
error NoActiveWithdrawRequest(uint256 campaignId);
error ChallangePeriodEnded(uint256 campaignId);
error NotCampaignCreator();
error CreatorCannotBeContributor(address _creator);
error AlreadySumbittedForDisputer(address _address);
