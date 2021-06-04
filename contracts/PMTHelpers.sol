// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract PMTHelpers {
    /// @dev Constructs a market ID from an oracle, a question ID, and the outcome slot count for the question.
    /// @param oracle The account assigned to report the result for the prepared condition.
    /// @param questionId An identifier for the question to be answered by the oracle.
    /// @param outcomeSlotCount The number of outcome slots which should be used for this condition. Must not exceed 8.
    function getMarketId(
        address oracle, 
        bytes32 questionId, 
        uint8 outcomeSlotCount
    ) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked(oracle, questionId, outcomeSlotCount));
    }

    /// @dev Constructs a outcome slot ID from the backing collateral token,
    /// a question ID, and the outcome slot count for the question.
    /// @param collateralToken The account assigned to report the result for the prepared condition.
    /// @param selectionIndex The order of outcome within the submitted outcome slot array.
    /// @param marketId An identifier for the market to add liquidity to.
    function getOutcomeSlotId(
        IERC20 collateralToken, 
        uint256 selectionIndex, 
        bytes32 marketId
    ) internal pure returns (uint256) {
        return uint256(keccak256(abi.encodePacked(collateralToken, selectionIndex, marketId)));
    }
}