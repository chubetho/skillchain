// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./FreelancerMarketplace.sol";
import "./EscrowManager.sol";
import "./UserManager.sol";

contract CommitteeManager {
  enum AcceptanceStatus {
    Pending,
    Accepted,
    Declined
  }
  enum MemberVote {
    Pending,
    No,
    Yes
  }
  enum MemberAvailability {
    Unavailable,
    Available
  }

  uint allCommitteeMemberCount;
  uint availableCommitteeMemberCount;

  FreelancerMarketplace freelancerMarketplace;
  EscrowManager escrowManager;
  UserManager userManager;

  struct ReviewRequest {
    address requester;
    uint newAmount;
    string reason;
    uint requiredCommitteeMembers;
    bool isClosed;
    AcceptanceStatus status;
  }

  struct CommitteeVote {
    address voterAddress;
    MemberVote vote;
  }

  struct CommitteeMember {
    address committeeMemberAddress;
    MemberAvailability availability;
  }

  // Mappings
  // key = allCommitteeMemberCount
  mapping(uint => CommitteeMember) public committeeMembers;
  // key = escrowId
  mapping(uint => ReviewRequest) public reviewRequests;
  // key = escrowId, value = array of CommitteeVotes
  mapping(uint => CommitteeVote[]) public committeeVotes;

  // Event definition
  event CommitteeReviewOpened(
    uint indexed escrowId,
    uint requiredCommitteeMembers
  );

  // Constructor to link to FreelancerMarketplace Address
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

  // Link Committee Manager with Escrow Manager
  function setEscrowManager(address _address) external {
    require(
      freelancerMarketplace.onlyAdmin(),
      "Only the Admin can add Managers"
    );
    escrowManager = EscrowManager(_address);
  }

  // Link Committee Manager with User Manager
  function setUserManager(address _address) external {
    require(
      freelancerMarketplace.onlyAdmin(),
      "Only the Admin can add Managers"
    );
    userManager = UserManager(_address);
  }

  // Function that allows Frontend to set random committee members
  function setCommitteeMembers(
    uint escrowId,
    address[] calldata selectedMembers
  ) external {
    require(
      freelancerMarketplace.onlyAdmin(),
      "Only the Admin can set committee members. msg.sender has to be the admin"
    );
    // Makes sure that the ammount of user addresses is equal the ammount of required committee members
    require(
      selectedMembers.length ==
        reviewRequests[escrowId].requiredCommitteeMembers,
      "Invalid number of committee members selected"
    );

    // Add the new committee member to the array of committee cotes for this escrow
    for (uint i = 0; i < selectedMembers.length; i++) {
      // Add the address and initialize his/her vote as Pending
      CommitteeVote memory newCommitteeVote = CommitteeVote({
        voterAddress: selectedMembers[i],
        vote: MemberVote.Pending
      });
      committeeVotes[escrowId].push(newCommitteeVote);
    }
  }

  //*********************************************************************
  //*********************************************************************
  //                        Getter Functions
  //*********************************************************************
  //*********************************************************************

  // Function to retrieve details of a review request
  function getReviewRequestDetails(
    uint escrowId
  )
    external
    view
    returns (
      address requester,
      uint newAmount,
      string memory reason,
      uint requiredCommitteeMembers,
      bool isClosed,
      AcceptanceStatus status
    )
  {
    // Retrieve the review request for the specified escrowId
    ReviewRequest storage request = reviewRequests[escrowId];

    // Return the details as a tuple
    return (
      request.requester,
      request.newAmount,
      request.reason,
      request.requiredCommitteeMembers,
      request.isClosed,
      request.status
    );
  }

  // Function to retrieve committee votes for a review request
  function getCommitteeVotes(
    uint escrowId
  )
    external
    view
    returns (address[] memory _voters, MemberVote[] memory _votes)
  {
    // Retrieve the review request for the specified escrowId
    ReviewRequest storage request = reviewRequests[escrowId];

    // Create arrays for voters and votes with the size of the required committee
    address[] memory voters = new address[](request.requiredCommitteeMembers);
    MemberVote[] memory votes = new MemberVote[](
      request.requiredCommitteeMembers
    );

    // Iterate through the committee votes and populate the arrays with voters and votes
    for (uint i = 0; i < committeeVotes[escrowId].length; i++) {
      voters[i] = committeeVotes[escrowId][i].voterAddress;
      votes[i] = committeeVotes[escrowId][i].vote;
    }

    // Return the arrays as a tuple
    return (voters, votes);
  }

  function getCommitteeMemberArray(
    uint escrowId
  ) external view returns (address[] memory) {
    // Get Review request for escrowId
    ReviewRequest storage request = reviewRequests[escrowId];

    // Initialize temporary empty array for assigned Members with the length of the required ammount of members
    address[] memory assignedMembers = new address[](
      request.requiredCommitteeMembers
    );

    // iterate through list of committee votes and add committeeMemberId (the key of his committeeMember mapping)to assigned members
    for (uint i = 0; i < request.requiredCommitteeMembers; i++) {
      assignedMembers[i] = committeeVotes[escrowId][i].voterAddress;
    }

    return assignedMembers;
  }

  // Returns the current ammount of available committee user
  function getAvailableCommitteeMemberCount() external view returns (uint) {
    return availableCommitteeMemberCount;
  }

  // Function to get the availability status of a specific committee member
  function getCommitteeMemberAvailability(
    address committeeMemberAddress
  ) external view returns (MemberAvailability) {
    // Iterate through the list of committee members
    for (uint i = 0; i < allCommitteeMemberCount; i++) {
      // Check if the current committee member's address matches the provided address
      if (
        committeeMembers[i].committeeMemberAddress == committeeMemberAddress
      ) {
        // If the member is found, return their availability status
        return committeeMembers[i].availability;
      }
    }

    // If the member is not found, revert with an error message
    revert("Member not found in the committee");
  }

  // Function that returns all available committee members as an array
  function getAllAvailableCommitteeMembers()
    external
    view
    returns (address[] memory)
  {
    // Initialize a temporary array to store available committee members
    address[] memory availableMembers = new address[](
      availableCommitteeMemberCount
    );

    // Counter for available committee members
    uint availableIndex = 0;

    // Iterate through the mapping committeeMembers
    for (uint i = 0; i < allCommitteeMemberCount; i++) {
      // Check if the committee member is available
      if (committeeMembers[i].availability == MemberAvailability.Available) {
        // Add the available committee member to the array
        availableMembers[availableIndex] = committeeMembers[i]
          .committeeMemberAddress;
        availableIndex++;
      }
    }

    // Return the array of available committee members
    return availableMembers;
  }

  //*********************************************************************
  //*********************************************************************
  //                        User Functions
  //*********************************************************************
  //*********************************************************************

  // Function for Users to join the committee pool, will be called in the UserManager
  // Function should only be called if not a part of committee pool yet
  function joinCommittee(address userAddress) external {
    // Set mapping for user being part of committee pool to check later
    committeeMembers[allCommitteeMemberCount] = CommitteeMember({
      committeeMemberAddress: userAddress,
      availability: MemberAvailability.Available
    });
    allCommitteeMemberCount++;
    availableCommitteeMemberCount++;
  }

  function markMemberAsUnavailable(address userAddress) external {
    // Check if the address is a committee member
    bool isCommitteeMember = false;
    uint memberIndex;

    for (uint i = 0; i < allCommitteeMemberCount; i++) {
      if (committeeMembers[i].committeeMemberAddress == userAddress) {
        isCommitteeMember = true;
        memberIndex = i;
        break;
      }
    }

    require(isCommitteeMember, "You are not a committee member");

    // Set the availability status to "Unavailable" for the committee member
    committeeMembers[memberIndex].availability = MemberAvailability.Unavailable;

    // Decrease the count of available committee members
    availableCommitteeMemberCount--;
  }

  //*********************************************************************
  //*********************************************************************
  //                        Committee Review Functions
  //*********************************************************************
  //*********************************************************************

  // This will be the function called from the Escrow Manager when Escrow is coming to an end and a user is not
  // happy with the result, so they will request a Committee Review
  // Review consists of new ammount (ether) and a string reason to describe why a review is requested
  function openCommitteeReview(
    uint escrowId,
    uint newAmount,
    string calldata _reason
  ) external onlyEscrowEntity(escrowId) {
    require(newAmount > 0, "New amount must be greater than 0");
    // Überprüfen, ob bereits eine Review-Anfrage für diese Escrow-ID geöffnet wurde
    require(
      !reviewRequests[escrowId].isClosed,
      "Review request already opened"
    );

    // Call function to determine how many committee members will be reviewing this Review Request
    uint requiredCommitteeMembers = determineRequiredCommitteeMembers(
      newAmount
    );

    // Create temporary Review Request instance in memory and assign the new values
    ReviewRequest memory newRequest = ReviewRequest({
      requester: msg.sender,
      newAmount: newAmount,
      reason: _reason,
      requiredCommitteeMembers: requiredCommitteeMembers,
      isClosed: false,
      status: AcceptanceStatus.Pending
    });

    // Permanently store the new review request in the mapping, with the escrowId as key
    reviewRequests[escrowId] = newRequest;

    // Trigger the event to notify the frontend
    emit CommitteeReviewOpened(escrowId, requiredCommitteeMembers);
  }

  // Committee Members can Vote true = Yes/ false = No on the Review request
  function voteReviewRequest(
    uint escrowId,
    bool _vote
  ) external onlyCommitteeMemberOfRequest(escrowId) {
    ReviewRequest storage request = reviewRequests[escrowId];
    require(!request.isClosed, "Review request is closed");

    for (uint i = 0; i < committeeVotes[escrowId].length; i++) {
      // check if sender matches the committee member address to make sure to store the vote for the right address
      if (committeeVotes[escrowId][i].voterAddress == msg.sender) {
        // Set vote Yes/No
        committeeVotes[escrowId][i].vote = _vote
          ? MemberVote.Yes
          : MemberVote.No;
        break;
      }
    }

    // Check if all votes are cast
    (bool allVoted, , ) = countVotes(
      escrowId,
      request.requiredCommitteeMembers
    );
    // If all votes are cast, close the committee review
    if (allVoted) {
      closeCommitteeReview(escrowId);
    }
  }

  //*********************************************************************
  //*********************************************************************
  //                        Internal Committee Functions
  //*********************************************************************
  //*********************************************************************

  // Not every Job must be reviewd by the same ammount of users, so we determine the ammount of committee users
  // based on the new ether ammount
  function determineRequiredCommitteeMembers(
    uint newAmount
  ) internal pure returns (uint) {
    if (newAmount <= 1) {
      return 3;
    } else if (newAmount <= 3) {
      return 5;
    } else if (newAmount <= 5) {
      return 7;
    } else {
      return 9;
    }
  }

  // Function to count votes for a review request
  function countVotes(
    uint escrowId,
    uint _requiredCommitteeMembers
  ) internal view returns (bool, uint, uint) {
    // Initialize counters for pending, yes, and no votes
    uint countPending = 0;
    uint countYes = 0;
    uint countNo = 0;

    // Loop through all committee votes for the specified review request
    for (uint i = 0; i < _requiredCommitteeMembers; i++) {
      // Get the vote of the committee member for the specified review request
      MemberVote currentVote = committeeVotes[escrowId][i].vote;

      // Check the vote and update the counters accordingly
      if (currentVote == MemberVote.Pending) {
        countPending++;
      } else if (currentVote == MemberVote.Yes) {
        countYes++;
      } else if (currentVote == MemberVote.No) {
        countNo++;
      }
    }

    // Return a tuple indicating if all votes are cast countPending == 0, along with counts of yes and no votes
    return (countPending == 0, countYes, countNo);
  }

  // Function to close a committee review based on the votes
  function closeCommitteeReview(uint escrowId) internal {
    // Get the review request based on the escrowId
    ReviewRequest storage request = reviewRequests[escrowId];

    // Mark the review request as closed
    request.isClosed = true;

    // Get the voting results using the countVotes function
    (bool allVoted, uint countYes, uint countNo) = countVotes(
      escrowId,
      request.requiredCommitteeMembers
    );

    // Check if all committee members have voted
    if (allVoted) {
      // Check the voting results and update the status of the review request
      if (countYes > countNo) {
        // Mark the request as accepted and execute
        request.status = AcceptanceStatus.Accepted;
        executeReview(escrowId);
        // Increase the available member counter again
        availableCommitteeMemberCount += request.requiredCommitteeMembers;
      } else {
        // Mark the request as declined and execute
        request.status = AcceptanceStatus.Declined;
        executeReview(escrowId);
        // Increase the available member counter again
        availableCommitteeMemberCount += request.requiredCommitteeMembers;
      }
    }
  }

  // Function to execute actions based on the review result
  function executeReview(uint escrowId) internal {
    // Check if the review request was accepted by the committee
    ReviewRequest storage request = reviewRequests[escrowId];
    require(
      request.status == AcceptanceStatus.Accepted ||
        request.status == AcceptanceStatus.Declined,
      "The committee did not vote on your review yet"
    );
    // Update the EscrowManager with the new amount if Request was accepted
    if (request.status == AcceptanceStatus.Accepted) {
      escrowManager.updateEscrow(escrowId, request.newAmount, true);
    } else if (request.status == AcceptanceStatus.Declined) {
      escrowManager.updateEscrow(escrowId, request.newAmount, false);
    }

    // Set Committee Members back to "Available"
    for (uint i = 0; i < committeeVotes[escrowId].length; i++) {
      // Find the index of the committee member in the committeeMembers mapping
      for (uint j = 0; j < allCommitteeMemberCount; j++) {
        if (
          committeeMembers[j].committeeMemberAddress ==
          committeeVotes[escrowId][i].voterAddress
        ) {
          // Set the availability status to "Available" for the committee member
          committeeMembers[j].availability = MemberAvailability.Available;
          break;
        }
      }
    }
  }

  //*********************************************************************
  //*********************************************************************
  //                        Modifiers
  //*********************************************************************
  //*********************************************************************

  // Make sure sender is part of the committee for this escrow
  modifier onlyCommitteeMemberOfRequest(uint escrowId) {
    bool isCommitteeMember = false;
    for (uint i = 0; i < committeeVotes[escrowId].length; i++) {
      if (committeeVotes[escrowId][i].voterAddress == msg.sender) {
        isCommitteeMember = true;
        break;
      }
    }

    require(
      isCommitteeMember,
      "you are not a part of the committee for this escrow"
    );

    // Continue with the execution of the function
    _;
  }

  // Modifier to ensure that the sender is a party to the specified escrow
  modifier onlyEscrowEntity(uint _escrowId) {
    // Get buyer and seller addresses from the EscrowManager based on the escrowId
    (, , address _buyer, address _seller, , , , ) = escrowManager.getEscrow(
      _escrowId
    );

    require(
      msg.sender == _buyer || msg.sender == _seller,
      "You are not a party to this escrow"
    );

    // Continue with the execution of the function
    _;
  }

  modifier onlyAuthorized(uint _escrowId) {
    bool isCommitteeMember = false;
    bool isEscrowEntity = false;

    (, , address _buyer, address _seller, , , , ) = escrowManager.getEscrow(
      _escrowId
    );

    if (msg.sender == _buyer || msg.sender == _seller) {
      isEscrowEntity = true;
    } else {
      for (uint i = 0; i < committeeVotes[_escrowId].length; i++) {
        if (committeeVotes[_escrowId][i].voterAddress == msg.sender) {
          isCommitteeMember = true;
          break;
        }
      }
    }

    require(
      isCommitteeMember || isEscrowEntity,
      "you are not a part of the committee or party of this escrow"
    );

    // Continue with the execution of the function
    _;
  }
}
