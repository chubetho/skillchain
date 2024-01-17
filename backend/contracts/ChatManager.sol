// SPDX-License-Identifier: MIT
pragma solidity >=0.8.2 <0.9.0;

import "./FreelancerMarketplace.sol";
import "./EscrowManager.sol";
import "./UserManager.sol";
import "./JobManager.sol";

contract ChatManager {
  enum ChannelStatus {
    Open,
    Closed
  }
  EscrowManager escrowManager;
  FreelancerMarketplace freelancerMarketplace;
  JobManager jobManager;
  UserManager userManager;
  uint channelCount;

  struct Channel {
    uint escrowId;
    address participantSeller;
    address participantBuyer;
    ChannelStatus channelStatus;
    uint messageCount;
  }

  struct Message {
    address sender;
    address receiver;
    uint timestamp;
    string content;
  }

  // Mappings to store channels and messages
  mapping(uint => Channel) public channels;
  mapping(uint => mapping(uint256 => Message)) private channelMessages;

  constructor(address _freelancerMarketplaceAddress) {
    freelancerMarketplace = FreelancerMarketplace(
      _freelancerMarketplaceAddress
    );
    channelCount = 0;
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

  // Retrieve details of a specific channel
  function getChannel(uint _escrowId) public view returns (Channel memory) {
    return channels[_escrowId];
  }

  // Retrieve details of a specific message in a channel
  function getMessage(
    uint _escrowId,
    uint _messageId
  ) public view returns (Message memory) {
    // Get channel by escrowId
    Channel storage channel = channels[_escrowId];

    // Ensure that the messageId is within a valid range
    require(_messageId < channel.messageCount, "Invalid messageId");

    return channelMessages[_escrowId][_messageId];
  }

  // Retrieve all messages in a channel
  function getAllChannelMessages(
    uint _escrowId
  ) public view returns (Message[] memory) {
    uint count = channels[_escrowId].messageCount;
    Message[] memory allMessages = new Message[](count);

    for (uint i = 0; i < count; i++) {
      allMessages[i] = channelMessages[_escrowId][i];
    }

    return allMessages;
  }

  //*********************************************************************
  //*********************************************************************
  //                        Channel Functions
  //*********************************************************************
  //*********************************************************************

  // Open a new communication channel for a given escrow
  function openChannel(uint _escrowId) public isEscrowEntity(_escrowId) {
    require(
      channels[_escrowId].participantSeller == address(0) &&
        channels[_escrowId].participantBuyer == address(0),
      "Channel is already opened!"
    );

    // Destruct escrow from getEscrow from EscrowManager to get the addresses of buyer and seller
    (, , address buyer, address seller, , , , ) = escrowManager.getEscrow(
      _escrowId
    );

    // Create a new Channel instance and store it in the mapping array
    channels[_escrowId] = Channel({
      escrowId: _escrowId,
      participantSeller: seller,
      participantBuyer: buyer,
      channelStatus: ChannelStatus.Open,
      messageCount: 0
    });

    channelCount++;
  }

  // Close an existing communication channel for a given escrow
  function closeChannel(uint _escrowId) public isEscrowEntity(_escrowId) {
    // Fetch the corresponding channel
    Channel storage channel = channels[_escrowId];

    // Ensure that the channel is currently open
    require(
      channel.channelStatus == ChannelStatus.Open,
      "Channel is not open."
    );

    // Update channel status to Closed
    channel.channelStatus = ChannelStatus.Closed;
  }

  //*********************************************************************
  //*********************************************************************
  //                        Message Functions
  //*********************************************************************
  //*********************************************************************

  // Send a message in the channel (channelId == escrowId)
  function sendMessage(
    uint _escrowId,
    string memory _content
  ) public isEscrowEntity(_escrowId) {
    // Get channel by escrowId
    Channel storage channel = channels[_escrowId];

    // Make sure only open Channels can be accessed
    require(channel.channelStatus == ChannelStatus.Open, "Channel not open");

    // Determine the receiver based on the sender
    address receiver = (msg.sender == channel.participantBuyer)
      ? channel.participantSeller
      : channel.participantBuyer;

    // Create a new Message and store it in the mapping array
    channelMessages[_escrowId][channel.messageCount] = Message({
      sender: msg.sender,
      receiver: receiver,
      timestamp: block.timestamp,
      content: _content
    });

    // Increase messageCount to ensure a unique ID for mapping
    channel.messageCount++;
  }

  //*********************************************************************
  //*********************************************************************
  //                        Modifier
  //*********************************************************************
  //*********************************************************************

  // Modifier to check if the caller is one of the EscrowParty
  modifier isEscrowEntity(uint256 _escrowId) {
    (, , address _buyer, address _seller, , , , ) = escrowManager.getEscrow(
      _escrowId
    );
    require(
      msg.sender == _buyer || msg.sender == _seller,
      "you are not party of this"
    );
    _;
  }
}
