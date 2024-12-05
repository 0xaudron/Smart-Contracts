// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.26;

/***
@title English Auction Contract - Very simple auction contract
@author 0xaudron - https://x.com/0xaudron

Features of English Auction:
1. Bidding 
2. Ascending prices
3. Winner Determination:

Flow of the processes:
Auction Initialization > Bidding Process > Auction End > Settle(Winner Anncounced)

Roles: 
- Manager (this contract)
- Seller
- Bidder 

***/
contract EnglishAuction {


// Constants
uint256 constant public FEES = 1000; //1% of the winner's bid will go to this contract as a form of maintenance
uint256 constant public NEXT_BID = 3000;    //Next bid should be more than 3% or else, it won't succeed

// State variables
struct Auction {
    address seller;
    uint256 startingPrice;  // base amount price
    uint256 highestBid;     // amount 
    address highestBidder;  // winner
    bool ended;             //
}
mapping(uint256 => Auction) public auctions;
uint256 public auctionId;
uint256 public auctionIdCounter;


//Events
event AuctionCreated(uint256 auctionId);
event BidPlaced(uint256 auctionId, address bidder, uint256 amount);
event AuctionEndedandSettled(uint256 auctionId);



function createAuction(uint256 _startingAmount) public  {
    auctionId = auctionIdCounter;
    //Init a new Auction struct
    auctions[auctionId] = Auction({
        seller: msg.sender,
        startingPrice : _startingAmount ,
        highestBid : 0,
        highestBidder : address(0),
        ended : false
    });

    emit AuctionCreated(auctionId);
    ++auctionIdCounter;
}

function placeBid(uint256 _auctionId) public payable {
    Auction storage auction = auctions[_auctionId];
    require(!auction.ended, "Sorry, the auction has ended");
    require(auction.seller != msg.sender, "Seller and bidder can't be same");
    if(auction.highestBid == 0){
        require(msg.value >= auction.startingPrice,"The amount is less than base price");
    }else {
        uint256 nextBidPrice = (auction.highestBid * NEXT_BID) /100000;
        require(msg.value >= nextBidPrice, "Should exceed 3% than highest bid");
        payable(auction.seller).transfer(auction.highestBid);
    }
    auction.highestBid = msg.value;
    auction.highestBidder = msg.sender;

    

    emit BidPlaced(_auctionId,msg.sender,msg.value);
}

function endAuction(uint256 _auctionId) public {
    Auction storage auction = auctions[_auctionId];
    require(auction.seller == msg.sender,"Wrong caller, can't end auction sorry");
    auction.ended = true;
    settlement(_auctionId);
}

function settlement(uint256 _auctionId) internal  {
    Auction storage auction = auctions[_auctionId];
    require(auction.ended, "Auction hasn't ended yet");
    require(auction.highestBidder != address(0), "No bid placed");
    
    uint256 FEE_AMOUNT = (auction.highestBid * FEES) / 100000;
    payable(address(this)).transfer(FEE_AMOUNT);
    uint256 SELLER_AMOUNT = auction.highestBid - FEE_AMOUNT;
    payable(auction.seller).transfer(SELLER_AMOUNT);

}
receive() external payable {}
}
