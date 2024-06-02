// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

contract Bidding {
    struct Project {
        address projectOwner;
        uint256 highestBidAmount;
        uint256 biddingAmount;
        uint256 endTime;
        bool projectStatus;
        address currentWinner;
        uint256 totalBidAmount;
        bool approve;
    }

    mapping(uint256 => Project) public projects;

    event ProjectStored(
        uint256 indexed projectId, address indexed projectOwner, uint256 biddingAmount, uint256 endTime
    );
    event BidPlaced(uint256 indexed projectId, address indexed bidder, uint256 amount);
    event AmountWithdrawn(uint256 indexed projectId, address indexed projectOwner, uint256 amount);

    AggregatorV3Interface internal priceFeed; // Chainlink Price Feed

    constructor(address _priceFeedAddress) {
        priceFeed = AggregatorV3Interface(_priceFeedAddress);
    }

    modifier onlyProjectOwner(uint256 id) {
        require(msg.sender == projects[id].projectOwner, "Only project owner can perform this action");
        _;
    }

    modifier biddingOpen(uint256 id) {
        require(projects[id].projectStatus && block.timestamp < projects[id].endTime, "Bidding has ended");
        _;
    }

    function storeProjectBid(uint256 projectId, address projectOwner, uint256 biddingAmount, uint256 endTime) public {
        projects[projectId] = Project({
            projectOwner: projectOwner,
            biddingAmount: biddingAmount,
            highestBidAmount: 0,
            endTime: endTime,
            projectStatus: true,
            currentWinner: address(0),
            totalBidAmount: 0,
            approve: true
        });
        emit ProjectStored(projectId, projectOwner, biddingAmount, endTime);
    }

    function placeBid(uint256 projectId) public payable biddingOpen(projectId) {
        Project storage project = projects[projectId];

        require(
            msg.value > project.highestBidAmount && msg.value > project.biddingAmount,
            "Bid amount should be higher than current highest bid and bidding amount."
        );
        require(msg.sender.balance >= msg.value, "Insufficient balance.");

        address projectWinner = project.currentWinner;

        // Update project details
        project.totalBidAmount += msg.value;
        project.highestBidAmount = msg.value;
        project.currentWinner = msg.sender;

        // Transfer bid amount from the previous winner
        if (projectWinner != address(0)) {
            payable(projectWinner).transfer(project.highestBidAmount);
        }
        if (project.endTime <= block.timestamp) {
            project.projectStatus = false;
        }
        emit BidPlaced(projectId, msg.sender, msg.value);
    }

    function withdrawAmount(uint256 id) public onlyProjectOwner(id) {
        Project storage project = projects[id];
        require(project.approve, "The highest Bidder hasn't approved the project");
        require(!project.projectStatus, "You can't Withdraw while the bid is ongoing");
        payable(project.projectOwner).transfer(project.highestBidAmount);
        emit AmountWithdrawn(id, project.projectOwner, project.highestBidAmount);
    }

    function getProjectBid(uint256 id)
        public
        view
        returns (address, uint256, uint256, address, uint256, uint256, bool, bool)
    {
        require(id != 0, "Project ID cannot be 0");
        Project memory project = projects[id];
        return (
            project.projectOwner,
            project.biddingAmount,
            project.highestBidAmount,
            project.currentWinner,
            project.endTime,
            project.totalBidAmount,
            project.projectStatus,
            project.approve
        );
    }

    function updateApproval(uint256 id) public returns (bool) {
        Project storage project = projects[id];
        require(msg.sender == project.currentWinner, "You are not the highest bidder");
        project.approve = true;
        return true;
    }

    function getLatestPrice() public view returns (uint256) {
        (
            uint80 roundID,
            int256 price,
            uint256 startedAt,
            uint256 timeStamp,
            uint80 answeredInRound
        ) = priceFeed.latestRoundData();
        return uint256(price);
    }
}
