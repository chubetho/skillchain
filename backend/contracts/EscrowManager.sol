// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0 <0.9.0;

import "./FreelancerMarketplace.sol";
import "./UserManager.sol";
import "./JobManager.sol";
import "./CommitteeManager.sol";
import "./ChatManager.sol";

contract EscrowManager {
  mapping(uint256 => Escrow) public escrows;
  uint256 escrowCount;
  FreelancerMarketplace freelancerMarketplace;
  JobManager jobManager;
  UserManager userManager;
  CommitteeManager committeeManager;
  ChatManager chatManager;

  struct Escrow {
    uint256 escrowId;
    uint256 jobId;
    address buyer;
    address seller;
    uint money;
    uint price;
    bool started;
    bool isDone;
    Request currentRequest;
  }

  struct SimplifiedEscrow {
    uint256 escrowId;
    uint256 jobId;
    address buyer;
    address seller;
    uint money;
    uint price;
    bool started;
    bool isDone;
  }

  enum RequestStatus {
    Start,
    Pending,
    Accepted,
    Declined
  }

  struct Request {
    address buyer;
    address seller;
    RequestStatus status;
    bool isStartRequest;
  }

  event EscrowCreated(
    uint256 escrowId,
    uint256 jobId,
    address buyer,
    address seller,
    uint price
  );

  constructor(address _freelancerMarketplaceAddress) {
    freelancerMarketplace = FreelancerMarketplace(
      _freelancerMarketplaceAddress
    );
  }

  //*********************************************************************
  //*********************************************************************
  //                        Setter Functions
  //*********************************************************************
  //*********************************************************************

  function setJobManager(address _address) external {
    require(
      freelancerMarketplace.onlyAdmin(),
      "Only the Admin can add Managers"
    );
    jobManager = JobManager(_address);
  }

  function setUserManager(address _address) external {
    require(
      freelancerMarketplace.onlyAdmin(),
      "Only the Admin can add Managers"
    );
    userManager = UserManager(_address);
  }

  function setCommitteeManager(address _address) external {
    require(
      freelancerMarketplace.onlyAdmin(),
      "Only the Admin can add Managers"
    );
    committeeManager = CommitteeManager(_address);
  }

  function setChatManager(address _address) external {
    require(
      freelancerMarketplace.onlyAdmin(),
      "Only the Admin can add Managers"
    );
    chatManager = ChatManager(_address);
  }

  //*********************************************************************
  //*********************************************************************
  //                        Getter Functions
  //*********************************************************************
  //*********************************************************************

  function getEscrowCount() external view returns (uint256 count) {
    return escrowCount;
  }

  function getEscrowIdFromJob(
    uint256 jobId
  ) external view returns (uint256 escrowId) {
    for (uint256 i = 0; i < escrowCount; i++) {
      if (escrows[i].jobId == jobId) {
        return i;
      }
    }
    revert("Escrow not found for the given job ID");
  }

  function getCurrentRequest(
    uint256 escrowId
  ) external view returns (Request memory) {
    require(escrowId < escrowCount, "Invalid escrow ID");
    Escrow storage escrow = escrows[escrowId];
    return escrow.currentRequest;
  }

  function getEscrow(
    uint256 escrowId
  )
    public
    view
    escrowExists(escrowId)
    returns (
      uint256 _escrowId,
      uint256 jobId,
      address buyer,
      address seller,
      uint money,
      uint price,
      bool started,
      bool isDone
    )
  {
    Escrow storage tempEscrow = escrows[escrowId];
    return (
      escrowId,
      tempEscrow.jobId,
      tempEscrow.buyer,
      tempEscrow.seller,
      tempEscrow.money,
      tempEscrow.price,
      tempEscrow.started,
      tempEscrow.isDone
    );
  }

  //*********************************************************************
  //*********************************************************************
  //                        Escrow Functions
  //*********************************************************************
  //*********************************************************************

  function createEscrow(address buyer, uint256 jobId, uint price) external {
    address seller = jobManager.getJobOwner(jobId);

    Escrow storage newEscrow = escrows[escrowCount];
    newEscrow.escrowId = escrowCount;
    newEscrow.jobId = jobId;
    newEscrow.buyer = buyer;
    newEscrow.seller = seller;
    newEscrow.price = price;

    userManager.addEscrowId(escrowCount, buyer);
    userManager.addEscrowId(escrowCount, seller);

    chatManager.openChannel(escrowCount);

    escrowCount++;

    emit EscrowCreated(escrowCount, jobId, buyer, seller, price);
  }

  //*********************************************************************
  //*********************************************************************
  //                        Request Functions
  //*********************************************************************
  //*********************************************************************

  function sendRequest(uint256 escrowId) external payable {
    require(escrowId < escrowCount, "Invalid escrow ID");
    Escrow storage escrow = escrows[escrowId];
    require(
      escrow.currentRequest.status != RequestStatus.Pending,
      "Cant Send a new request while current one is pending"
    );
    require(!escrow.started, "Escrow must not be started");
    require(
      msg.sender == escrow.buyer,
      "Only the Buyer can send the Start Request"
    );
    require(msg.value == escrow.price, "invalid Funds");

    escrow.money += msg.value;
    escrow.started = true;

    escrow.currentRequest = Request({
      buyer: msg.sender,
      seller: escrow.seller,
      status: RequestStatus.Pending,
      isStartRequest: true
    });
  }

  function respondToRequest(uint256 escrowId, bool accept) external {
    require(escrowId < escrowCount, "Invalid escrow ID");
    Escrow storage escrow = escrows[escrowId];
    require(
      escrow.currentRequest.status == RequestStatus.Pending,
      "You can only interact with pending requests"
    );

    require(
      msg.sender == escrow.seller,
      "Only the Seller can accept the End Request"
    );

    if (accept) {
      escrowDone(escrow);
      escrow.currentRequest.status = RequestStatus.Accepted;
    } else {
      escrow.currentRequest.status = RequestStatus.Declined;
    }
  }

  //*********************************************************************
  //*********************************************************************
  //                        Acceptance Functions
  //*********************************************************************
  //*********************************************************************

  // Function to update the Escrow price after committee vote
  function updateEscrow(
    uint escrowId,
    uint newAmount,
    bool accepted
  ) external onlyCommitteeMember(escrowId) {
    // Ensure that the escrow is not marked as done
    require(!escrows[escrowId].isDone, "Escrow is already completed");

    Escrow storage currentEscrow = escrows[escrowId];
    // Check if Committee accpeted the request or not, if yes handle refund and update escrow price
    // if not mark escrow as Done
    if (accepted) {
      uint refundAmount = currentEscrow.money - newAmount;
      // Update the escrow with the new amount

      // The differing ammount will be sent back to the buyer
      if (refundAmount > 0) {
        // TO-DO: Hier schauen, wie genau die Zahlung abläuft
        payable(currentEscrow.buyer).transfer(refundAmount);
        refundAmount = 0;
      }
      currentEscrow.money = newAmount;
    }
    // TO-DO: Prüfen ob escrowDone schon aufgerufen werden kann
    escrowDone(currentEscrow);
  }

  function escrowDone(Escrow storage escrow) internal {
    payable(escrow.seller).transfer(escrow.money);
    escrow.money = 0;
    escrow.isDone = true;
    chatManager.closeChannel(escrow.escrowId);
  }

  function cancelEscrow(uint256 escrowId) external isEscrowParty(escrowId) {
    Escrow storage currentEscrow = escrows[escrowId];

    require(!currentEscrow.started, "Cannot cancel a started escrow");

    payable(currentEscrow.buyer).transfer(currentEscrow.money);

    // Reset the escrow state
    currentEscrow.buyer = address(0);
    currentEscrow.seller = address(0);
    currentEscrow.money = 0;
    currentEscrow.started = false;
    currentEscrow.isDone = false;

    // Close ChatChannel
    chatManager.closeChannel(escrowId);
    chatManager.sendMessage(escrowId, "This escrow was canceled");
  }

  //*********************************************************************
  //*********************************************************************
  //                        Modifiers
  //*********************************************************************
  //*********************************************************************

  modifier escrowExists(uint256 escrowId) {
    require(escrowId <= escrowCount, "Escrow does not exist");
    _;
  }

  modifier isEscrowParty(uint256 escrowId) {
    require(
      msg.sender == escrows[escrowId].seller ||
        msg.sender == escrows[escrowId].buyer,
      "You are not involved in the escrow"
    );
    _;
  }

  modifier isSeller(uint256 escrowId) {
    require(
      msg.sender == escrows[escrowId].seller,
      "You are not the seller in the escrow"
    );
    _;
  }

  modifier isBuyer(uint256 escrowId) {
    require(
      msg.sender == escrows[escrowId].buyer,
      "You are not the buyer in the escrow"
    );
    _;
  }

  modifier onlyCommitteeMember(uint escrowId) {
    bool _isCommitteeMember = false;
    address[] memory committeeMemberArray = committeeManager
      .getCommitteeMemberArray(escrowId);
    for (uint i = 0; i < committeeMemberArray.length; i++) {
      if (committeeMemberArray[i] == msg.sender) {
        _isCommitteeMember = true;
        break;
      }
    }

    require(
      _isCommitteeMember,
      "you are not a part of the committee for this escrow"
    );

    // Continue with the execution of the function
    _;
  }
}
