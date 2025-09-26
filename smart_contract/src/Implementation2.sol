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
  function emrWithdraw(uint256 campaignId) external payable {
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
}
