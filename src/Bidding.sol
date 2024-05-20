// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

contract Biddding {
    struct Project {
        address projectOwner;
        uint256 highestBidAmount;
        uint256 biddingAmount;
        uint256 endTime;
        //true means it is still ongoing false means otherwise.
        bool projectStatus;
        address winner;
        uint256 totalBidAmount;
        bool approve;
    }

    mapping(uint256 => Project) public projects;

    function StoreProjectBid(uint256 projectId, address project_owner, uint256 bidding_amount, uint256 endTime)
        public
    {
        projects[projectId] = Project({
            projectOwner: project_owner,
            biddingAmount: bidding_amount,
            highestBidAmount: 0,
            endTime: endTime,
            projectStatus: true,
            currentWinner: address(0),
            approve :true
        });
        // You will Add An event here;
    }

    function placeBid(uint256 projectId, address user, uint256 amount) public payable {
        Project storage project = projects[projectId];

        require(
            amount > project.highestBidAmount && amount > project.biddingAmount,
            "Bid amount should be higher than current highest bid and bidding amount."
        );
        if (block.timestamp < project.endTime || project.projectStatus == false) revert("Bidding has ended.");
        // require(block.timestamp < project.endTime, "");

        require(user.balance >= amount, "Insufficient balance.");

        address projectWinner = project.currentWinner;

        // Update project details
        project.totalBidAmount += amount;
        project.highestBidAmount = amount;
        project.currentWinner = payable(user);

        // Transfer bid amount from the previous winner
        if (projectWinner != address(0)) {
            payable(projectWinner).transfer(project.highestBidAmount);
        }
        if (project.endTime <= block.timestamp) {
            project.projectStatus = false;
        }
    }
    // Check if the auction end time has passed

    function withdrawAmount(address user,uint256 id) {
         Project storage project = projects[id];
        require(user==project.projectOwner,"You are not the owner of this Project you can't make withdrawals");
        require(project.approve=true,)
        payable(project.projectOwner).transfer(project.highestBidAmount);
        // This function will emit an event.
    }

    function getProjectBid(uint256 id)
        public
        view
        returns (address, uint256, uint256, address, uint256, uint256, bool)
    {
        require(id != 0, "{id} Field Cannot be 0");
        Project memory project = projects[id];
        return (
            project.project_owner,
            project.biddingAmount,
            project.highestBidAmount,
            project.currentWinner,
            project.endTime,
            project.totalBidAmount,
            project.projectStatus,
            project.approval
        );
    }

    function updateApproval() public returns (bool) {}
}
