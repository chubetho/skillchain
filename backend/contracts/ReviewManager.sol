// SPDX-License-Identifier: MIT
pragma solidity >=0.8.2 <0.9.0;

import "./EscrowManager.sol";
import "./FreelancerMarketplace.sol";

contract ReviewManager {
  // State variables
  uint public reviewCount;
  EscrowManager escrowManager;
  FreelancerMarketplace freelancerMarketplace;

  // Structs to represent reviews and responses
  struct Review {
    uint timestamp;
    uint rating;
    address reviewingAddress;
    address beingReviewedAddress;
    string reviewComment;
    uint relevantEscrowId;
    bool responded; // Indicates if a response has been added
  }

  struct Response {
    uint timestamp;
    address responder;
    string responseComment;
  }

  // Mappings to store reviews and responses, and track reviewed and responded status
  mapping(uint => Review) public reviews;
  mapping(uint => Response) public responses;
  mapping(uint => mapping(address => bool)) public hasReviewed;
  mapping(uint => mapping(address => bool)) public hasResponded;

  // Constructor to initialize reviewCount
  constructor() {
    reviewCount = 1;
  }

  // Function to create a new review
  function createReview(
    uint _escrowId,
    uint _rating,
    string calldata _reviewComment
  ) external {
    require(escrowManager.isEscrowEntity(_escrowId));
    // Check if msg.sender has not already reviewed for the given escrowId
    require(
      !hasReviewed[_escrowId][msg.sender],
      "You can only review once for this escrowId"
    );

    // Ensure that the review comment is not empty
    require(
      freelancerMarketplace.nonEmptyString(_reviewComment),
      "Review comment must not be empty"
    );

    // Destruct escrow from getEscrow from EscrowManager to get the addresses of buyer and seller
    (, , address buyer, address seller, , , , ) = escrowManager.getEscrow(
      _escrowId
    );
    address _reviewingAddress = msg.sender;
    address _beingReviewedAddress = (msg.sender == buyer) ? seller : buyer;

    // Create a new Review object
    Review memory newReview = Review({
      timestamp: block.timestamp,
      rating: _rating,
      reviewingAddress: _reviewingAddress,
      beingReviewedAddress: _beingReviewedAddress,
      reviewComment: _reviewComment,
      relevantEscrowId: _escrowId,
      responded: false
    });

    // Add the new review to the reviews mapping
    reviews[reviewCount] = newReview;

    // Mark that msg.sender has reviewed for the given escrowId
    hasReviewed[_escrowId][msg.sender] = true;

    // Increment the number of reviews for the next unique reviewId
    reviewCount++;
  }

  // Function to create a response to a review
  function createResponse(
    uint _reviewId,
    string calldata _responseComment
  ) external validReviewId(_reviewId) {
    // Check if the responder is the beingReviewedAddress in the review
    require(
      msg.sender == reviews[_reviewId].beingReviewedAddress,
      "You can only respond to reviews where you are being reviewed"
    );

    // Check if the review has not already been responded to
    require(
      !reviews[_reviewId].responded,
      "The review has already been responded to"
    );

    // Ensure that the response comment is not empty
    require(
      freelancerMarketplace.nonEmptyString(_responseComment),
      "Response must not be empty"
    );

    // Create a new Response object
    Response memory newResponse = Response({
      timestamp: block.timestamp,
      responder: msg.sender,
      responseComment: _responseComment
    });

    // Add the new response to the responses mapping
    responses[_reviewId] = newResponse;

    // Mark that msg.sender has responded to the given review
    hasResponded[_reviewId][msg.sender] = true;

    // Mark the corresponding review as responded
    reviews[_reviewId].responded = true;
  }

  // Function to retrieve details of a specific review
  function getReview(
    uint _reviewId
  )
    external
    view
    validReviewId(_reviewId)
    returns (
      uint timestamp,
      uint rating,
      address reviewingAddress,
      address beingReviewedAddress,
      string memory reviewComment,
      uint relevantEscrowId,
      bool responded
    )
  {
    Review storage review = reviews[_reviewId];
    return (
      review.timestamp,
      review.rating,
      review.reviewingAddress,
      review.beingReviewedAddress,
      review.reviewComment,
      review.relevantEscrowId,
      review.responded
    );
  }

  // Function to retrieve details of a response to a review
  function getResponse(
    uint _reviewId
  )
    external
    view
    validReviewId(_reviewId)
    returns (uint timestamp, address responder, string memory responseComment)
  {
    // Check if a response is available for this review
    require(
      reviews[_reviewId].responded,
      "No response available for this review"
    );

    Response storage response = responses[_reviewId];
    return (response.timestamp, response.responder, response.responseComment);
  }

  // Function to get all reviews for a specific user where the user is being reviewed
  function getReviewsForUser(
    address _user
  ) external view returns (uint[] memory) {
    uint[] memory userReviews = new uint[](reviewCount);
    uint userReviewCount = 0;

    for (uint i = 1; i <= reviewCount; i++) {
      if (reviews[i].beingReviewedAddress == _user) {
        userReviews[userReviewCount] = i;
        userReviewCount++;
      }
    }

    // Resize the array to remove unused slots
    assembly {
      mstore(userReviews, userReviewCount)
    }

    return userReviews;
  }

  // Function to get all reviews for a specific user where the user is reviewing
  function getReviewsFromUser(
    address _user
  ) external view returns (uint[] memory) {
    uint[] memory userReviews = new uint[](reviewCount);
    uint userReviewCount = 0;

    for (uint i = 1; i <= reviewCount; i++) {
      if (reviews[i].reviewingAddress == _user) {
        userReviews[userReviewCount] = i;
        userReviewCount++;
      }
    }

    // Resize the array to remove unused slots
    assembly {
      mstore(userReviews, userReviewCount)
    }

    return userReviews;
  }

  // Modifier to check if the reviewId is valid
  modifier validReviewId(uint _reviewId) {
    require(_reviewId > 0 && _reviewId < reviewCount, "Invalid reviewId");
    _;
  }
}
