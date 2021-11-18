// SPDX-License-Identifier: MIT
pragma solidity 0.8.3;

//import '@openzeppelin/contracts/token/ERC721/IERC721.sol';
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC721/IERC721.sol";

contract Auctioning {
    
  
  struct Auction {
    address payable seller;
    uint minBid;
    uint endDate;
    address payable highestBidAddress;
    uint highestBidAmount;
  }
  mapping(address => mapping(uint => Auction)) public auctions;
//uint public listingFe ether;
  event AuctionCreated(
    address tokenAddress,
    uint tokenId,
    address seller,
    uint minBid,
    uint endDate
  );

  function createAuction(
    address _tokenAddress, 
    uint _tokenId,
    uint _minBid
  ) 
  external 
  {
    Auction storage auction = auctions[_tokenAddress][_tokenId];
    
    //require(msg.value >= listingFee, "pay the listing fees");
    require(auction.endDate == 0, "auction already exist"); 
    IERC721(_tokenAddress).transferFrom(msg.sender, address(this), _tokenId);
    auction.seller = payable(msg.sender); 
    auction.minBid = _minBid; 

    auction.endDate = block.timestamp + 7 * 86400; 
    auction.highestBidAddress = payable( address(0));
    auction.highestBidAmount = 0;

    emit AuctionCreated({
      tokenAddress: _tokenAddress,
      tokenId: _tokenId,
      seller: msg.sender, 
      minBid: _minBid, 
      endDate: block.timestamp + 7 * 86400
    });
  }

  function createBid(address _tokenAddress, uint _tokenId) external payable {
    Auction storage auction = auctions[_tokenAddress][_tokenId];
    require(auction.endDate != 0, 'auction does not exist');
    require(auction.endDate >= block.timestamp, 'auction is finished');
    require(
      auction.highestBidAmount < msg.value && auction.minBid < msg.value, 
      'bid amount is too low'
    );
    //reimburse previous bidder
    auction.highestBidAddress.transfer(auction.highestBidAmount);
    auction.highestBidAddress = payable(msg.sender);
    auction.highestBidAmount = msg.value; 
  }

  function closeBid(address _tokenAddress, uint _tokenId) external {
    Auction storage auction = auctions[_tokenAddress][_tokenId];
    require(auction.endDate != 0, 'auction does not exist');
    require(auction.endDate < block.timestamp, 'auction has not finished');
    if(auction.highestBidAmount == 0) {
      //auction failed, no bidder showed up.
      IERC721(_tokenAddress).transferFrom(address(this), auction.seller, _tokenId);
      delete auctions[_tokenAddress][_tokenId];
    } else {
      //auction succeeded, send money to seller, and token to buyer
      auction.seller.transfer(auction.highestBidAmount);
      IERC721(_tokenAddress).transferFrom(address(this), auction.highestBidAddress, _tokenId);
      delete auctions[_tokenAddress][_tokenId];
    }
  }
}
