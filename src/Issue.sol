// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

contract Issue {
    struct Issue {
        address plaintiff;
        address defendant;
        uint256 pVoteCount;
        uint256 dVoteCount;
        bool status;
        uint256 endTime;
    }

    mapping(address => bool) public hasVoted;
    mapping(bytes32 => Issue) public issues;

    event Voted(address indexed voter, bytes32 indexed issueId);

    AggregatorV3Interface internal priceFeed; // Chainlink Price Feed

    constructor(address _priceFeedAddress) {
        priceFeed = AggregatorV3Interface(_priceFeedAddress);
    }

    function createIssue(bytes32 issueId, address _plaintiff, address _defendant, uint256 _endTime) public {
        require(issues[issueId].endTime == 0, "Issue already exists");
        issues[issueId] = Issue({
            plaintiff: _plaintiff,
            defendant: _defendant,
            pVoteCount: 0,
            dVoteCount: 0,
            status: true,
            endTime: _endTime
        });
    }

    function vote(bytes32 issueId, address candidate) public {
        Issue storage issue = issues[issueId];
        require(issue.status, "Issue is closed");
        require(block.timestamp <= issue.endTime, "Voting period has ended");
        require(!hasVoted[msg.sender], "You have already voted");

        if (candidate == issue.plaintiff) {
            issue.pVoteCount++;
        } else if (candidate == issue.defendant) {
            issue.dVoteCount++;
        } else {
            revert("Invalid candidate");
        }

        hasVoted[msg.sender] = true;
        emit Voted(msg.sender, issueId);
    }

    function getIssue(bytes32 id) public view returns (address, address, uint256, uint256, bool, uint256) {
        Issue storage issue = issues[id];
        require(issue.endTime != 0, "Issue does not exist");
        return (
            issue.plaintiff,
            issue.defendant,
            issue.pVoteCount,
            issue.dVoteCount,
            issue.status,
            issue.endTime
        );
    }

    function getWinner(bytes32 id) public view returns (address) {
        Issue storage issue = issues[id];
        require(!issue.status, "Can't view result until issue is closed");

        if (issue.pVoteCount > issue.dVoteCount) {
            return issue.plaintiff;
        } else if (issue.dVoteCount > issue.pVoteCount) {
            return issue.defendant;
        } else {
            return address(0); // Indicates a draw
        }
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
