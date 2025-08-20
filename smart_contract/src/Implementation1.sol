// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.22;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/ReentrancyGuardUpgradeable.sol";

contract Implementation1 is
    Initializable,
    OwnableUpgradeable,
    ReentrancyGuardUpgradeable
{
    uint256 public campaignCount;
    // campings struct
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
    mapping(uint256 => Campaign) public campaigns;

    // events
    event CampaignCreated(uint256 indexed id, address creator);
    event CampaignContributed(uint256 indexed id, address funder);
    event CampaignWithdrawn(uint256 indexed id, address creater);
    event CampaignRefunded(uint256 indexed id, address funder);
    event CampaignExtended(uint256 indexed id, address creater);
    // modifiers
    modifier onlyFunder(uint256 _campaignId) {
        require(
            campaigns[_campaignId].funders[msg.sender] > 0,
            "You are not a funder of this campaign"
        );
        _;
    }

    // initilizer
    function initialize() public initializer {
        __Ownable_init(msg.sender);
        __ReentrancyGuard_init();
    }

    // create campaigns
    function createCampaign(
        string memory ipfsHash,
        uint256 goal,
        uint256 deadline
    ) external {
        require(deadline > block.timestamp, "deadline is not reached");
        campaignCount++;
        Campaign storage newCampaign = campaigns[campaignCount];
        newCampaign.id = campaignCount;
        newCampaign.ipfsHash = ipfsHash;
        newCampaign.deadline = deadline;
        newCampaign.goal = goal;
        newCampaign.raised = 0;
        newCampaign.creator = msg.sender;
        newCampaign.active = true;
        emit CampaignCreated(campaignCount, msg.sender);
    }

    // constribute
    function constribute(uint256 campaignId) external payable nonReentrant {
        require(campaigns[campaignId].active == true, "campaign is not active");
        require(
            campaigns[campaignId].deadline > block.timestamp,
            "campaign is over"
        );
        require(msg.value > 0, "no ether sent");
        campaigns[campaignId].raised += msg.value;
        campaigns[campaignId].funders[msg.sender] += msg.value;
    }

    // withdraw
    function withdrawFunds(uint256 campaignId) external nonReentrant {
        _onlyCreater(campaignId);
        _checkDeadline(campaigns[campaignId].deadline);
        _checkGoal(campaigns[campaignId].goal, campaignId);
        uint256 amount = campaigns[campaignId].raised;
        (bool success, ) = payable(msg.sender).call{value: amount}("");
        require(success, "transfer failed");
        campaigns[campaignId].active = false;
        campaigns[campaignId].raised = 0;
        emit CampaignWithdrawn(campaignId, msg.sender);
    }

    // refund
    function refund(
        uint256 campaignId
    ) external onlyFunder(campaignId) nonReentrant {
        require(campaigns[campaignId].active == true, "campaign is not active");

        uint256 funderAmount = campaigns[campaignId].funders[msg.sender];
        (bool success, ) = payable(msg.sender).call{value: funderAmount}("");
        require(success, "transfer failed");
        campaigns[campaignId].raised -= funderAmount;
        campaigns[campaignId].funders[msg.sender] = 0;
        emit CampaignRefunded(campaignId, msg.sender);
    }

    // extend deadline
    function extendDeadline(uint256 campaignId, uint256 newDeadline) external {
        _onlyCreater(campaignId);
        require(
            newDeadline > block.timestamp &&
                newDeadline > campaigns[campaignId].deadline,
            "deadline is not reached"
        );
        campaigns[campaignId].deadline = newDeadline;
        emit CampaignExtended(campaignId, msg.sender);
    }

    // only creater campign function
    function _onlyCreater(uint256 _campaignId) internal view {
        if (campaigns[_campaignId].creator != msg.sender) {
            revert("only creator");
        }
    }

    // helper  function to check deadline
    function _checkDeadline(uint256 _deadline) internal view {
        if (_deadline < block.timestamp) {
            revert("campaigns is over ");
        }
    }

    // helper  function  to check goal
    function _checkGoal(uint256 _goal, uint256 _campaignId) internal view {
        if (campaigns[_campaignId].raised < _goal) {
            revert("goal is not reached");
        }
    }
}
