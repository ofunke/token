// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

contract CustomPriceOracle {
    uint256 private price; // Store the price
    address public owner; // Owner of the oracle

    // Event for price updates
    event PriceUpdated(uint256 oldPrice, uint256 newPrice);

    constructor() {
        owner = msg.sender; // Set the deployer as the owner
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Not the owner");
        _;
    }

    // Function to update the price (only owner can call)
    function updatePrice(uint256 newPrice) external onlyOwner {
        uint256 oldPrice = price;
        price = newPrice;
        emit PriceUpdated(oldPrice, newPrice);
    }

    // Function to fetch the latest price
    function latestPrice() external view returns (uint256) {
        return price;
    }

    // Function to transfer ownership
    function transferOwnership(address newOwner) external onlyOwner {
        require(newOwner != address(0), "Invalid address");
        owner = newOwner;
    }
}