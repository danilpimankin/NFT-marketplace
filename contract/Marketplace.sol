// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "./ERC721.sol";

contract Marketplace is MyToken{
using SafeERC20 for IERC20;
IERC20 public token;

uint _auctionDuration = 3 days;  
uint _auctionMinBidders = 2;


mapping(uint => Auction) private _auctions;
mapping(uint => Listing) private _listings;


struct Auction{
    address seller;
    address buyer;
    uint winnerRate;
    uint finishAt;
    uint amountBids;
}

struct Listing  {
    address owner;
    uint price;
}

constructor(address _token) {
    token = IERC20(_token);
}

event CreateItem(address indexed _creator, address indexed _owner, uint indexed _tokenId);
event ListItem(address indexed _seller, uint indexed _tokenId, uint _price);
event BuyItem(address indexed _buyer, uint indexed _tokenId, uint _price);
event CancelListing(uint indexed _tokenId, address indexed _seller);

event ListItemOnAuction(address indexed _seller, uint indexed _tokenId, uint _minPrice, uint startAt, uint _finishAt);
event MakeBid(address indexed _bidder, uint indexed _tokenId, uint _amountRate);
event FinishAuction(address indexed _winner, uint indexed _tokenId, uint _totalPrice, uint _finishAt);
event CancelAuction(uint indexed _tokenId, uint _finishAt);




function createItem(address _to, string calldata uri) external returns(uint tokenId){
    tokenId = mint(_to, uri); 

    emit CreateItem(msg.sender, _to, tokenId);
} 

function listItem(uint _tokenId, uint _price) external {
    require(ownerOf(_tokenId) == msg.sender, "You are not an owner");
    require(_price > 0, "Price should be positive");
    Listing storage listing = _listings[_tokenId];

    _transfer(msg.sender, address(this), _tokenId);

    listing.owner = msg.sender;
    listing.price = _price;

    emit ListItem(msg.sender, _tokenId, _price);
}

function buyItem(uint _tokenId) external {
    Listing storage listing = _listings[_tokenId];
    require(balanceOf(msg.sender) >= listing.price, "Not enough tokens");
    require(listing.owner != address(0), "Item is not selling");

    token.safeTransferFrom(msg.sender, address(this), listing.price);
    _transfer(address(this), msg.sender, _tokenId);
    
    delete listing.owner;

    emit BuyItem(msg.sender, listing.price, _tokenId);
}   

function cancelListing(uint _tokenId) external {
    require(ownerOf(_tokenId) == msg.sender, "You are not an owner");
    Listing storage listing = _listings[_tokenId];

    _transfer(address(this), msg.sender, _tokenId);

    delete listing.owner;

    emit CancelListing(_tokenId, listing.owner);    
}

function listItemOnAuction(uint _tokenId, uint _minPrice) external {
    require(ownerOf(_tokenId) == msg.sender, "You are not an owner");
    require(_minPrice > 0, "Price should be positive");
    
    Auction storage auction = _auctions[_tokenId];

    uint _finishAt = block.timestamp + _auctionDuration;
    auction.seller = msg.sender;
    auction.winnerRate = _minPrice;
    auction.finishAt = _finishAt;

    emit ListItemOnAuction(msg.sender, _tokenId, _minPrice, block.timestamp, _finishAt);
}

function makeBid(uint _tokenId, uint _price) external {
    Auction storage auction = _auctions[_tokenId];
    // require(balanceOf(msg.sender) >= auction.winnerRate,  "not enough fund");
    require(auction.seller != address(0), "Item is not selling");
    require(_price > auction.winnerRate, "not enough fund");
    require(block.timestamp < auction.finishAt, "Auction is over");

    token.safeTransferFrom(msg.sender, address(this), _price);
    
    if(auction.buyer != address(0)) {
        token.safeTransfer(auction.buyer, auction.winnerRate); 
    }

    auction.winnerRate = _price;
    auction.amountBids++;
    auction.buyer = msg.sender;

    emit MakeBid(msg.sender, _tokenId, _price);
}

function finishAuction(uint _tokenId) external { 
    Auction storage auction = _auctions[_tokenId];
    require(auction.seller != address(0), "Auction is not active");
    require(block.timestamp >= auction.finishAt, "Auction is not over");

    bool success;

    if(auction.amountBids >= _auctionMinBidders) {
        token.safeTransferFrom(address(this), auction.seller, auction.winnerRate);
        _transfer(address(this), auction.buyer, _tokenId);
        success = true;
    } else {
        token.safeTransferFrom(address(this), auction.buyer, auction.winnerRate);
        _transfer(address(this), auction.seller, _tokenId);
    }

    delete auction.seller;

    emit FinishAuction(auction.buyer, _tokenId, auction.winnerRate, block.timestamp);
}

function cancelAuction(uint _tokenId) external {
    Auction storage auction = _auctions[_tokenId];
    require(auction.seller == msg.sender, "You are not the owner of this auction");
    require(auction.seller != address(0), "Auction is not active");
    require(block.timestamp < auction.finishAt, "Auction is already finished");

    if(auction.buyer != address(0)) {
        token.safeTransfer(auction.buyer, auction.winnerRate); 
    }
    _transfer(address(this), auction.seller, _tokenId);
    
    delete auction.seller;

    emit CancelAuction(_tokenId, block.timestamp);
}

function setMinBidders(uint _minBid) external {
    _auctionMinBidders = _minBid;
}

function setAuctionDuration(uint _duration) external {
    _auctionDuration = _duration;
}

function getItemCurrentPrice(uint _tokenId) external view returns(uint) {
    Auction storage auction = _auctions[_tokenId];
    return auction.winnerRate;
}

}