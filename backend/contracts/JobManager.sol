// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./UserManager.sol";
import "./EscrowManager.sol";
import "./FreelancerMarketplace.sol";

contract JobManager {
  mapping(uint256 => Job) public jobs;
  uint256 public jobCount;

  FreelancerMarketplace freelancerMarketplace;
  EscrowManager escrowManager;
  UserManager userManager;

  struct BuyRequest {
    uint256 jobId;
    uint256 buyRequestId;
    address buyer;
    string comment;
    bool accepted;
    int256 escrowId;
  }

  struct Job {
    address owner;
    uint256 jobId;
    string title;
    string description;
    uint price;
    mapping(uint256 => BuyRequest) buyRequests;
    uint256 buyRequestCount;
    bool inProgress;
    string[] tags;
  }

  struct SimplifiedJob {
    address owner;
    uint256 jobId;
    string title;
    string description;
    uint price;
    bool inProgress;
    string[] tags;
  }

  event JobAdded(
    address owner,
    string title,
    string description,
    uint price,
    string[] tags
  );

  event ToggledJob(bool inProgress);

  event JobDeleted(address userAddress, uint256 jobId);

  constructor(address _freelancerMarketplaceAddress) {
    freelancerMarketplace = FreelancerMarketplace(
      _freelancerMarketplaceAddress
    );
  }

  //*********************************************************************
  //*********************************************************************
  //                        Utility Functions
  //*********************************************************************
  //*********************************************************************

  function isUserInArray() external view returns (bool) {
    address[] memory allUsers = userManager.getAllUserAddresses();
    address sender = msg.sender;

    for (uint256 i = 0; i < allUsers.length; i++) {
      if (allUsers[i] == sender) {
        return true;
      }
    }

    return false;
  }

  //*********************************************************************
  //*********************************************************************
  //                        Setter Functions
  //*********************************************************************
  //*********************************************************************

  function setEscrowManager(address _address) external {
    require(
      freelancerMarketplace.onlyAdmin(),
      "Only the Admin can add Managers"
    );
    escrowManager = EscrowManager(_address);
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

  function getJobOwner(uint256 jobId) external view returns (address _address) {
    return jobs[jobId].owner;
  }

  function getJob(uint256 id) external view returns (SimplifiedJob memory) {
    Job storage job = jobs[id];
    return
      SimplifiedJob({
        owner: job.owner,
        jobId: job.jobId,
        title: job.title,
        description: job.description,
        price: job.price,
        inProgress: job.inProgress,
        tags: job.tags
      });
  }

  function getAllJobs() external view returns (SimplifiedJob[] memory) {
    SimplifiedJob[] memory allJobs = new SimplifiedJob[](jobCount);

    for (uint256 i = 0; i < jobCount; i++) {
      allJobs[i] = SimplifiedJob({
        owner: jobs[i].owner,
        jobId: jobs[i].jobId,
        title: jobs[i].title,
        description: jobs[i].description,
        price: jobs[i].price,
        inProgress: jobs[i].inProgress,
        tags: jobs[i].tags
      });
    }

    return allJobs;
  }

  function getAllJobsOfUser(
    address _owner
  ) external view returns (SimplifiedJob[] memory) {
    uint256[] memory userJobIds = userManager.getAllJobIds(_owner);
    SimplifiedJob[] memory allUserJobs = new SimplifiedJob[](userJobIds.length);

    for (uint256 i = 0; i < userJobIds.length; i++) {
      Job storage job = jobs[userJobIds[i]];
      allUserJobs[i] = SimplifiedJob({
        owner: job.owner,
        jobId: job.jobId,
        title: job.title,
        description: job.description,
        price: job.price,
        inProgress: job.inProgress,
        tags: job.tags
      });
    }

    return allUserJobs;
  }

  function getJobBuyRequests(
    uint256 jobId
  )
    external
    view
    jobExists(jobId)
    isAUser
    isJobOwner(jobId)
    returns (BuyRequest[] memory)
  {
    Job storage job = jobs[jobId];
    uint256 counter = job.buyRequestCount;
    BuyRequest[] memory allJobBuyRequests = new BuyRequest[](counter);

    for (uint256 i = 0; i < counter; i++) {
      allJobBuyRequests[i] = job.buyRequests[i];
    }

    return allJobBuyRequests;
  }

  //*********************************************************************
  //*********************************************************************
  //                        Job Functions
  //*********************************************************************
  //*********************************************************************

  function addJob(
    string memory title,
    string memory description,
    uint price,
    string[] memory tags
  ) public isAUser {
    require(
      freelancerMarketplace.nonEmptyString(title),
      "Title must not be empty"
    );
    require(
      freelancerMarketplace.nonEmptyString(description),
      "Description must not be empty"
    );

    Job storage newJob = jobs[jobCount];
    newJob.owner = msg.sender;
    newJob.title = title;
    newJob.description = description;
    newJob.price = price;
    newJob.jobId = jobCount;
    newJob.inProgress = false;
    newJob.tags = tags;

    userManager.addJobId(jobCount, msg.sender);

    jobCount++;

    emit JobAdded(msg.sender, title, description, price, tags);
  }

  function toggleJob(uint256 jobId) external isJobOwner(jobId) isAUser {
    jobs[jobId].inProgress = !jobs[jobId].inProgress;

    emit ToggledJob(jobs[jobId].inProgress);
  }

  function deleteJob(
    uint256 jobId
  ) public jobExists(jobId) isJobOwner(jobId) notInProgress(jobId) {
    userManager.removeJobId(jobId, msg.sender);
    delete jobs[jobId];

    emit JobDeleted(msg.sender, jobId);
  }

  //*********************************************************************
  //*********************************************************************
  //                        BuyRequest Functions
  //*********************************************************************
  //*********************************************************************

  function sendBuyRequest(
    uint256 jobId,
    string memory comment
  ) public isAUser jobExists(jobId) isNotJobOwner(jobId) notInProgress(jobId) {
    require(
      freelancerMarketplace.nonEmptyString(comment),
      "Comment must not be empty"
    );

    Job storage currentJob = jobs[jobId];
    BuyRequest storage request = currentJob.buyRequests[
      currentJob.buyRequestCount
    ];
    request.jobId = jobId;
    request.buyer = msg.sender;
    request.comment = comment;
    request.buyRequestId = currentJob.buyRequestCount;
    request.accepted = false;
    request.escrowId = -1;

    currentJob.buyRequestCount++;
  }

  function acceptBuyRequest(
    uint256 jobId,
    uint256 buyRequestId
  ) public isAUser jobExists(jobId) isJobOwner(jobId) notInProgress(jobId) {
    Job storage currentJob = jobs[jobId];
    BuyRequest storage currentBuyRequest = currentJob.buyRequests[buyRequestId];
    currentBuyRequest.accepted = true;
    currentBuyRequest.escrowId = int256(escrowManager.getEscrowCount());

    escrowManager.createEscrow(
      currentBuyRequest.buyer,
      jobId,
      jobs[jobId].price
    );
  }

  //*********************************************************************
  //*********************************************************************
  //                        Modifier
  //*********************************************************************
  //*********************************************************************

  modifier isAUser() {
    address[] memory allUsers = userManager.getAllUserAddresses();
    address sender = msg.sender;
    bool pass = false;
    for (uint256 i = 0; i < allUsers.length; i++) {
      if (allUsers[i] == sender) {
        pass = true;
      }
    }

    require(pass, "You need a User for this Action");
    _;
  }

  modifier isJobOwner(uint256 jobId) {
    require(
      msg.sender == jobs[jobId].owner,
      "You need to be the owner of the job"
    );
    _;
  }

  modifier isNotJobOwner(uint256 jobId) {
    require(msg.sender != jobs[jobId].owner, "You cannot buy your own job");
    _;
  }

  modifier notInProgress(uint256 jobId) {
    require(
      !jobs[jobId].inProgress,
      "Job is in progress and cannot be modified"
    );
    _;
  }

  modifier jobExists(uint256 jobId) {
    require(jobId <= jobCount, "Job does not exist");
    _;
  }
}
