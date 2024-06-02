// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Transction{
    struct Transaction {
        uint256 projectId;
        address payer;
        address payee;
        uint256 amount;
        bool isFundsDeposited;
        bool isFundsApproved;
        bool isFundsReleased;
    }

    mapping(uint256 => Transaction) public transactions;
    uint256 public transactionCount;

    event TransactionCreated(uint256 indexed transactionId, uint256 projectId, address indexed payer, address indexed payee);
    event FundsDeposited(uint256 indexed transactionId, address indexed payer, uint256 amount);
    event FundsApproved(uint256 indexed transactionId, address indexed payer);
    event FundsReleased(uint256 indexed transactionId, address indexed payee, uint256 amount);
    event FundsRefunded(uint256 indexed transactionId, address indexed payer, uint256 amount);

    function createTransaction(uint256 _projectId, address _payee) external returns (uint256) {
        transactionCount++;
        transactions[transactionCount] = Transaction({
            projectId: _projectId,
            payer: msg.sender,
            payee: _payee,
            amount: 0,
            isFundsDeposited: false,
            isFundsApproved: false,
            isFundsReleased: false
        });
        emit TransactionCreated(transactionCount, _projectId, msg.sender, _payee);
        return transactionCount;
    }

    function deposit(uint256 _transactionId) external payable {
        Transaction storage transaction = transactions[_transactionId];
        require(!transaction.isFundsDeposited, "Funds already deposited");
        require(msg.value > 0, "Deposit amount should be greater than zero");
        require(msg.sender.balance >= msg.value, "Insufficient balance to deposit");
        require(msg.sender == transaction.payer, "Only the payer can deposit funds");

        transaction.amount = msg.value;
        transaction.isFundsDeposited = true;

        emit FundsDeposited(_transactionId, transaction.payer, transaction.amount);
    }

    function approveFunds(uint256 _transactionId) external {
        Transaction storage transaction = transactions[_transactionId];
        require(msg.sender == transaction.payer, "Only payer can approve funds");
        require(transaction.isFundsDeposited, "No funds to approve");
        require(!transaction.isFundsApproved, "Funds already approved");

        transaction.isFundsApproved = true;

        emit FundsApproved(_transactionId, transaction.payer);
    }

    function releaseFunds(uint256 _transactionId) external {
        Transaction storage transaction = transactions[_transactionId];
        require(transaction.isFundsDeposited, "No funds to release");
        require(transaction.isFundsApproved, "Funds not approved by payer");
        require(!transaction.isFundsReleased, "Funds already released");
        require(msg.sender == transaction.payer, "Only the payer can release the funds");

        transaction.isFundsReleased = true;
        payable(transaction.payee).transfer(transaction.amount);

        emit FundsReleased(_transactionId, transaction.payee, transaction.amount);
    }

    function refundFunds(uint256 _transactionId) external {
        Transaction storage transaction = transactions[_transactionId];
        require(transaction.isFundsDeposited, "No funds to refund");
        require(!transaction.isFundsReleased, "Funds already released");
        require(msg.sender == transaction.payee, "Only the payee can refund the funds");

        transaction.isFundsReleased = true;
        payable(transaction.payer).transfer(transaction.amount);

        emit FundsRefunded(_transactionId, transaction.payer, transaction.amount);
    }
}
