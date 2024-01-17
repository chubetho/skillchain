// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0 <0.9.0;

import "./FreelancerMarketplace.sol";
import "./UserManager.sol";
import "./JobManager.sol";

contract EscrowManager {
  mapping(uint256 => Escrow) public escrows;
  uint256 escrowCount;
  FreelancerMarketplace freelancerMarketplace;
  JobManager jobManager;
  UserManager userManager;

  struct Escrow {
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

  //*********************************************************************
  //*********************************************************************
  //                        Getter Functions
  //*********************************************************************
  //*********************************************************************

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
    newEscrow.jobId = jobId;
    newEscrow.buyer = buyer;
    newEscrow.seller = seller;
    newEscrow.price = price;

    userManager.addEscrowId(escrowCount, buyer);
    userManager.addEscrowId(escrowCount, seller);

    emit EscrowCreated(escrowCount, jobId, buyer, seller, price);

    escrowCount++;
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
      "Cant Send a new request while currentone is pending"
    );
    bool starter;
    if (!escrow.started) {
      require(
        msg.sender == escrow.buyer,
        "Only the Buyer can send the Start Request"
      );
      require(msg.value < escrow.price, "invalid Funds");
      escrows[escrowId].money += msg.value;
      starter = true;
    } else {
      require(
        msg.sender == escrow.seller,
        "Only the Seller can send the End Request"
      );
      starter = false;
    }

    escrow.currentRequest = Request({
      buyer: msg.sender,
      seller: escrow.seller,
      status: RequestStatus.Pending,
      isStartRequest: starter
    });
  }

  function respondToRequest(uint256 escrowId, bool accept) external {
    require(escrowId < escrowCount, "Invalid escrow ID");
    Escrow storage escrow = escrows[escrowId];
    require(
      escrow.currentRequest.status == RequestStatus.Pending,
      "You can only interact with pending requests"
    );
    bool isStartRequest;

    if (!escrow.started) {
      require(
        msg.sender == escrow.seller,
        "Only the Seller can accpet the Start Request"
      );
      isStartRequest = true;
    } else {
      require(
        msg.sender == escrow.buyer,
        "Only the Buyer can accept the End Request"
      );
      isStartRequest = false;
    }

    if (accept) {
      if (!escrow.started) {
        escrow.started = true;
      } else {
        escrowDone(escrow);
      }
      escrow.currentRequest.status = RequestStatus.Accepted;
    } else {
      if (!escrow.started) {
        payable(escrow.buyer).transfer(escrow.money);
        escrow.money = 0;
      }
      escrow.currentRequest.status = RequestStatus.Declined;
    }
  }

  //*********************************************************************
  //*********************************************************************
  //                        Acceptance Functions
  //*********************************************************************
  //*********************************************************************

  function escrowDone(Escrow storage escrow) internal {
    payable(escrow.buyer).transfer(escrow.money);
    escrow.money = 0;
    escrow.isDone = true;
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

  // Function to call modifier isEscrowParty from outsid
  function isEscrowEntity(
    uint _escrowId
  ) public view isEscrowParty(_escrowId) returns (bool) {
    return true;
  }
}
