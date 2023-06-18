// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ArchonToken.sol";

contract ArchonMarket {
    struct Listing {
        address seller;
        uint256 price;
        string dataCid;
        bool isActive;
    }

    address public admin;
    ArchonToken public token;
    mapping(uint256 => Listing) public listings;
    uint256 public listingId;

    event ListingCreated(uint256 indexed id, address indexed seller, uint256 price, string dataCid);
    event ListingUpdated(uint256 indexed id, uint256 price);
    event ListingPurchased(uint256 indexed id, address indexed buyer, uint256 price);

    modifier onlyAdmin() {
        require(msg.sender == admin, "Only admin can call this function");
        _;
    }

    constructor(address _admin, address _tokenAddress) {
        admin = _admin;
        token = ArchonToken(_tokenAddress);
    }

    function createListing(uint256 _price, string memory _dataCid) external {
        require(_price > 0, "Price must be greater than zero");

        Listing storage listing = listings[listingId];
        listing.seller = msg.sender;
        listing.price = _price;
        listing.dataCid = _dataCid;
        listing.isActive = true;

        emit ListingCreated(listingId, msg.sender, _price, _dataCid);

        listingId++;
    }

    function updateListing(uint256 _id, uint256 _price) external {
        Listing storage listing = listings[_id];
        require(listing.isActive, "Listing is not active");
        require(msg.sender == listing.seller, "Only seller can update the listing");

        listing.price = _price;

        emit ListingUpdated(_id, _price);
    }

    function purchaseListing(uint256 _id) external payable {
        Listing storage listing = listings[_id];
        require(listing.isActive, "Listing is not active");
        require(listing.price == msg.value, "Incorrect payment amount");

        listing.isActive = false;

        token.transferFrom(listing.seller, msg.sender, listing.price);

        payable(admin).transfer(msg.value);

        emit ListingPurchased(_id, msg.sender, listing.price);
    }

    function withdrawFunds() external onlyAdmin {
        payable(admin).transfer(address(this).balance);
    }
}
