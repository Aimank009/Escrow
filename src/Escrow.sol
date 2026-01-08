// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

contract Escrow {
    
    address public buyer;
    address public seller;
    address public arbitrator;

    enum EscrowState{
        Initialized,
        Funded,
        Delivered,
        Disputed,
        Completed,
        Refunded,
        Cancelled
    }

    EscrowState public escrowState;

    uint256 public escrowAmount;


    event EscrowCreated(
        address indexed buyer,
        address indexed seller,
        address indexed arbitrator,
        uint256 escrowAmount
    );

    event FundDeposited(
        address indexed buyer,
        uint256 amount
    );

    event DeliveryConfirmed(
        address indexed seller
    );
    event DeliveryApproved(
        address indexed buyer,
        uint256 amount
    );
    event DisputeRaised(
        address indexed raisedBy
    );
    event DisputeResolved(
        address indexed winner,
        uint256 amount
    );

    event EscrowCancelled(
        address
    );

    constructor(
        address _buyer,
        address _seller,
        address _arbitrator,
        uint256 _escrowAmount
    ){
        require(_buyer!=address(0),"Invalid Buyer");
        require(_seller!=address(0),"Invalid seller");
        require(_arbitrator!=address(0),"Invalid arbitrator");
        require(_escrowAmount>0,"Amount should be greater than 0");

        buyer=_buyer;
        seller=_seller;
        arbitrator=_arbitrator;
        escrowAmount=_escrowAmount;

        escrowState=EscrowState.Initialized;

        emit EscrowCreated(buyer, seller, arbitrator, escrowAmount);
    }

    

    function depositFunds() external payable{
        require(msg.sender==buyer,"Only buyer can deposit");
        require(escrowState==EscrowState.Initialized,"Escrow is not initialized yet");
        require(msg.value==escrowAmount,"Incorrect deposit Amount");

        escrowState=EscrowState.Funded;

        emit FundDeposited(buyer, msg.value);
    }

    function confirmDelivery() external {
        require(msg.sender==seller,"Only seller can confirm Delivery");
        require(escrowState==EscrowState.Funded,"Escrow not Funded");

        escrowState=EscrowState.Delivered;

        emit DeliveryConfirmed(seller);
    }

    function approveDelivery()external{
        require(msg.sender==buyer,"Only buyer can approve delivery");
        require(escrowState==EscrowState.Funded || escrowState==EscrowState.Delivered ,"Escrow not ready for approval");

        escrowState=EscrowState.Completed;

        (bool success,)= seller.call{value:escrowAmount}("");
        require(success,"Transfer Failed");
        emit DeliveryApproved(buyer, escrowAmount);
    }

    function raiseDispute() external{
        require(msg.sender==buyer || msg.sender==seller ,"Only seler or buyer can dispute");
        require(escrowState==EscrowState.Funded || escrowState==EscrowState.Delivered ,"Escrow not disputable");

        escrowState=EscrowState.Disputed;

        emit DisputeRaised(msg.sender);
    }

    function resolveDispute(bool releaseToSeller) external {
        require(msg.sender==arbitrator,"Only arbitrator can resolve dispute");
        require(escrowState==EscrowState.Disputed,"Escrow not under dispute");

        escrowState=releaseToSeller?EscrowState.Completed:EscrowState.Refunded;

        address recipient = releaseToSeller?seller:buyer;

        (bool success,)=recipient.call{value:escrowAmount}("");
        require(success,"ETH transfer Failed");

        emit DisputeResolved(recipient, escrowAmount);
    }

    function cancelEscrow()external{
        require(msg.sender == buyer || msg.sender==seller, "Only buyer or seller can Cancel Escrow");
        require(escrowState==EscrowState.Initialized,"Escrow cannnot be cancelled now");

        escrowState=EscrowState.Cancelled;

    }
}
