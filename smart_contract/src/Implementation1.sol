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
        address[] funders;
        bool active;
    }
    mapping(uint256 => Campaign) public campaigns;

    // events
    event CampaignCreated(uint256 indexed id, address creator);

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
        campaigns[campaignCount] = Campaign(
            campaignCount,
            ipfsHash,
            deadline,
            goal,
            0,
            msg.sender,
            new address[](0),
            true
        );
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
        campaigns[campaignId].funders.push(msg.sender);
    }
}
