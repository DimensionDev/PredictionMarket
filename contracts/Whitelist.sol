//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import '@openzeppelin/contracts/access/Ownable.sol'; 

/// @title Whitelist for stablecoin addresses to be used as collateral in the prediction markets
contract CollateralWhitelist is Ownable {
    address[] public whitelist;
    // Each address maps to its corresponding index in whitelist[] + 1. A value of >=1 represents a whitelisted address.
    mapping(address => uint256) public isWhitelisted;

    // Initial stablecoin whitelist: USDT, USDC, BUSD, DAI, UST, TUSD
    constructor() {
        address[6] memory existingWhitelist = [
            0xdAC17F958D2ee523a2206206994597C13D831ec7, // USDT
            0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48, // USDC
            0x4Fabb145d64652a948d72533023f6E7A623C7C53, // BUSD
            0x6B175474E89094C44Da98b954EedeAC495271d0F, // DAI
            0xa47c8bf37f92aBed4A126BDA807A7b7498661acD, // UST
            0x0000000000085d4780B73119b644AE5ecd22b376  // TUSD
        ];
        for (uint8 i; i < existingWhitelist.length; i++) {
            isWhitelisted[existingWhitelist[i]] = i + 1;
            whitelist.push(existingWhitelist[i]);
        }
    }

    function addToWhitelist(address collateral) onlyOwner external {
        isWhitelisted[collateral] = whitelist.length + 1;
        whitelist.push(collateral);
    }

    function addMultipleToWhitelist(address[] calldata collateral) onlyOwner external {
        for (uint256 i; i < collateral.length; i++) {
            whitelist.push(collateral[i]);
            isWhitelisted[collateral[i]] = whitelist.length;
        }
    }

    function removeFromWhitelist(address collateral) onlyOwner external {
        require(whitelist.length > 0, "No address is whitelisted");
        uint256 whitelistIndex = isWhitelisted[collateral] - 1;
        require(whitelistIndex >= 0, "Collateral address has not been added to whitelist");

        if (whitelist.length > 1 && whitelistIndex != whitelist.length - 1) {
            whitelist[whitelistIndex] = whitelist[whitelist.length - 1];
            isWhitelisted[whitelist[whitelist.length - 1]] = whitelistIndex + 1;
        }

        delete whitelist[whitelist.length - 1];
        isWhitelisted[collateral] = 0;
    }

    function removeMultipleFromWhitelist(address[] calldata collateral) onlyOwner external {
        for (uint256 i; i < collateral.length; i++) {
            require(whitelist.length > 0, "No address is whitelisted");
            uint256 whitelistIndex = isWhitelisted[collateral[i]] - 1;
            require(whitelistIndex >= 0, "Collateral address has not been added to whitelist");

            if (whitelist.length > 1 && whitelistIndex != whitelist.length - 1) {
                whitelist[whitelistIndex] = whitelist[whitelist.length - 1];
                isWhitelisted[whitelist[whitelist.length - 1]] = whitelistIndex + 1;
            }

            delete whitelist[whitelist.length - 1];
            isWhitelisted[collateral[i]] = 0;
        }
    }
}