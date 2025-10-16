// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.22;

import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import {OwnableUpgradeable} from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import {ReentrancyGuardUpgradeable} from "@openzeppelin/contracts-upgradeable/utils/ReentrancyGuardUpgradeable.sol";
import "./error/ContractErrors.sol";
import "./libraries/CrownFundingLogic.sol";

contract Implementation2 is
    Initializable,
    OwnableUpgradeable,
    ReentrancyGuardUpgradeable
{
    using CrownFundingLogic for CrownFundingLogic.Campaign;

    uint256 campaignCount;
    // map of campaign
    mapping(uint256 => CrownFundingLogic.Campaign) public campaigns;
    // events

    event NewCampaignCreated(
        uint256 indexed campaignId,
        address indexed creator
    );
    event ConstributeToCampaign(
        uint256 indexed campaignId,
        address indexed constributor
    );
    event WithdrawFromCampaign(
        uint256 indexed campaignId,
        address indexed creator
    );
    event DisputedFiled(
        uint256 indexed campaignId,
        address indexed _disputerAddress
    );
    event DisputeThresholdMet(
        uint256 indexed campaignId,
        address indexed _disputerAddress,
        uint256 lengthOfDisputer
    );

    // disabled constructor
    constructor() {
        _disableInitializers();
    }

    function _initilizer() public initializer {
        __Ownable_init(msg.sender);
        __ReentrancyGuard_init();
    }

    // receive eth
    receive() external payable {}

    // modifiers
    modifier onlyFunders(uint256 campaignId) {
        require(
            campaigns[campaignId].funders[msg.sender] > 0,
            MustBeAFunderToRefund(msg.sender)
        );
        _;
    }

    // create a new campaign
    function createCampaign(
        string calldata ipfsHash,
        uint256 duration,
        uint256 goal
    ) external {
        uint256 deadline = block.timestamp + duration;
        if (deadline < block.timestamp) revert DeadlineMustBeInTheFuture();
        if (goal == 0) revert GoalMustBeGreaterThanZero();
        if (bytes(ipfsHash).length == 0) revert CampaignDetailsMustRequired();
        campaignCount++;
        CrownFundingLogic.Campaign storage newCampaign = campaigns[
            campaignCount
        ];
        newCampaign.ipfsHash = ipfsHash;
        newCampaign.goal = goal;
        newCampaign.deadline = deadline;
        newCampaign.id = campaignCount;
        newCampaign.raised = 0;
        newCampaign.active = true;
        newCampaign.creator = msg.sender;
        newCampaign.withdrawStatus = CrownFundingLogic.WithdrawStatus.Pending;
        newCampaign.challangePeriodEndAt = 0;
        newCampaign.disputedBy = new address[](0);
        newCampaign.withdrawRequestedAt = 0;

        emit NewCampaignCreated(campaignCount, msg.sender);
    }

    // constribute to campaign
    function constribute(uint256 campaignId) external payable {
        require(msg.value != 0, "You Don't have enough eth to constribute");
        CrownFundingLogic.Campaign storage constributeToCampaign = campaigns[
            campaignId
        ];
        constributeToCampaign.validateCampaign(campaignId);
        constributeToCampaign.ensureNotCreator(msg.sender);
        constributeToCampaign.raised += msg.value;
        constributeToCampaign.funders[msg.sender] += msg.value;
        emit ConstributeToCampaign(campaignId, msg.sender);
    }

    // request for withdraw funds
    function requestWithdrawal(uint256 campaignId) external {
        CrownFundingLogic.Campaign storage campaign = campaigns[campaignId];
        campaign.validateCampaign(campaignId);
        campaign.onlyCreator(msg.sender);

        if (campaign.raised < campaign.goal) revert GoalNotMeetYet(campaignId);

        if (campaign.deadline < block.timestamp)
            revert CampaignEnded(campaignId);

        campaign.withdrawStatus = CrownFundingLogic.WithdrawStatus.Requested;
        campaign.withdrawRequestedAt = block.timestamp;
        campaign.challangePeriodEndAt = block.timestamp + 7 days;
    }

    // withdraw funds
    function finalizeWithdrawal(uint256 campaignId) external nonReentrant {
        CrownFundingLogic.Campaign storage withdrawFromCampaign = campaigns[
            campaignId
        ];
        withdrawFromCampaign.isCreatorEligibleToFinilizeWithdraw(campaignId);

        (bool success, ) = payable(msg.sender).call{
            value: withdrawFromCampaign.raised
        }(" ");

        require(success, TransferFailed(campaignId, msg.sender));
        withdrawFromCampaign.withdrawStatus = CrownFundingLogic
            .WithdrawStatus
            .Completed;
        emit WithdrawFromCampaign(campaignId, msg.sender);
    }

    // file dispute
    function fileDispute(uint256 campaignId) external onlyFunders(campaignId) {
        CrownFundingLogic.Campaign storage fileDisputeFromCampaign = campaigns[
            campaignId
        ];
        require(
            fileDisputeFromCampaign.withdrawStatus ==
                CrownFundingLogic.WithdrawStatus.Requested,
            NoActiveWithdrawRequest(campaignId)
        );
        require(
            block.timestamp < fileDisputeFromCampaign.challangePeriodEndAt,
            ChallangePeriodEnded(campaignId)
        );
        fileDisputeFromCampaign.alreadySumbittedForDisputer();

        // stored new funders to disputed array
        fileDisputeFromCampaign.disputedBy.push(msg.sender);
        emit DisputedFiled(campaignId, msg.sender);

        // check if enough disputer then make withdraw disputed
        if (fileDisputeFromCampaign.isEnoughDisputer()) {
            fileDisputeFromCampaign.withdrawStatus = CrownFundingLogic
                .WithdrawStatus
                .Disputed;
            emit DisputeThresholdMet(
                campaignId,
                msg.sender,
                fileDisputeFromCampaign.disputedBy.length
            );
        }
    }

    // refund from campaign
    function refund(
        uint256 campaignId
    ) external nonReentrant onlyFunders(campaignId) {
        CrownFundingLogic.Campaign storage refundFromCampaign = campaigns[
            campaignId
        ];
        refundFromCampaign.invalidCampaign(campaignId);
    }
}
