// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { ERC1155 } from "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import { PMTHelpers } from "./PMTHelpers.sol";

contract PredictionMarketTokens is ERC1155, PMTHelpers {
    address public contractCreator;

    constructor(string memory marketUri) ERC1155(marketUri) {
        contractCreator = msg.sender;
    }

    // outcomeDetails maps marketId to outcome details. It has 2 sections that totals to 256 bits:
    // First 252 bits: Stores the eported outcomes, where each outcome takes 4 bits in little endian byte order. 
    //                 From the back, the first outcome slot takes bits 5-9, second takes 10-14 and so on. 
    //                 A successful outcome is 1000, an unsuccessful one is 0000.
    //                 An example of this in a 2-outcome market would be `0b [insert 244 zeros here] 0000 1000 0010`.
    // Following 4 bits: Number of outcome slots (e.g. for 4 outcome slots, 0100)
    mapping(bytes32 => uint256) public outcomeDetails;

    /// @dev Emitted upon the successful preparation of a condition.
    event MarketPrepSuccess(
        bytes32 indexed conditionId,
        address indexed oracle,
        bytes32 indexed questionId,
        uint256 outcomeSlotCount
    );

    /// @dev Emitted when liquidity provider successfully mints new outcome slot tokens.
    event MintSuccess(
        address indexed stakeholder,
        IERC20 collateralToken,
        bytes32 indexed marketId,
        uint256 amount
    );

    /// @dev Emitted when liquidity provider successfully removes stake in outcome slot tokens in exchange for collateral.
    event MergeSuccess(
        address indexed stakeholder,
        IERC20 collateralToken,
        bytes32 indexed marketId,
        uint256 amount
    );

    /// @dev Emitted upon an oracle's successful reporting of the market outcomes.
    event OutcomeReportSucess(
        bytes32 indexed marketId,
        address indexed oracle,
        bytes32 indexed questionId,
        uint256 outcomeSlotCount,
        uint256 reportedOutcome
    );

    /// @dev Emitted upon a successful redemption of collateral tokens based on winning outcomes.
    event RedeemWinningsSuccess(
        address indexed redeemer,
        IERC20 indexed collateralToken,
        bytes32 marketId,
        uint256 totalPayout
    );

    /**
     * @dev Prepares a condition by initializing a payout vector associated with the condition.
     * @param oracle The account assigned to report the result for the prepared condition.
     * @param questionId An identifier for the question to be answered by the oracle.
     * @param outcomeSlotCount The number of outcome slots which should be used for this condition. Must not exceed 15.
     */
    function prepareMarket(address oracle, bytes32 questionId, uint256 outcomeSlotCount) external {
        require(outcomeSlotCount <= 15, "Too many outcome slots");
        require(outcomeSlotCount > 1, "There should be more than one outcome slot");
        // marketId identifies the entire market condition: oracle, questionId and number of outcome slots
        bytes32 marketId = getMarketId(oracle, questionId, outcomeSlotCount);
        require(outcomeDetails[marketId] == 0, "Market already prepared");

        outcomeDetails[marketId] = outcomeSlotCount;

        emit MarketPrepSuccess(marketId, oracle, questionId, outcomeSlotCount);
    }

    /**
     * @dev To mint new market token sets, generally used for adding liquidity to the exchange pool.
     * E.g. If question has outcomes A and B, 10 COLLATERAL TOKENS will give 10 A and 10 B tokens.
     * @param collateralToken The address of the backing collateral token.
     * @param marketId An identifier for the market to add liquidity to.
     * @param amount The amount of new market token sets for minting.
     */
    function mintMarketTokenSet(
        IERC20 collateralToken,
        bytes32 marketId,
        uint256 amount
    ) external {
        uint256 outcomeSlotCount = outcomeDetails[marketId] % 16;
        require(outcomeSlotCount > 0, "Market not prepared yet");
        require(amount > 0, "Amount added for liquidity needs to be non-zero");

        uint256[] memory outcomeSlotIds = new uint256[](outcomeSlotCount);
        uint256[] memory amounts = new uint256[](outcomeSlotCount); // same amount for each outcome
        for (uint256 i = 0; i < outcomeSlotCount; i++) {
            outcomeSlotIds[i] = getOutcomeSlotId(collateralToken, i, marketId);
            amounts[i] = amount;
        }

        _mintBatch(
            msg.sender,
            outcomeSlotIds, // ERC-1155 token ID
            amounts,
            ""
        );

        emit MintSuccess(msg.sender, collateralToken, marketId, amount);
    }

    /**
     * @dev To merge previously created market token sets, generally used for removing liquidity from the exchange pool.
     * E.g. If question has outcomes A and B, merging 10 A and 10 B tokens will give 10 COLLATERAL TOKENS.
     * @param collateralToken The address of the backing collateral token.
     * @param marketId An identifier for the market to add liquidity to.
     * @param amount The amount of new market token sets for minting.
     */
    function mergeMarketTokenSet(
        IERC20 collateralToken,
        bytes32 marketId,
        uint256 amount
    ) external {
        uint256 outcomeSlotCount = outcomeDetails[marketId] % 16;
        require(outcomeSlotCount > 0, "Market not prepared yet");
        require(amount > 0, "Amount to withdraw liquidity needs to be non-zero");

        uint256[] memory outcomeSlotIds = new uint256[](outcomeSlotCount);
        uint256[] memory amounts = new uint256[](outcomeSlotCount); // same amount for each outcome
        for (uint256 i = 0; i < outcomeSlotCount; i++) {
            outcomeSlotIds[i] = getOutcomeSlotId(collateralToken, i, marketId);
            amounts[i] = amount;
        }

        _burnBatch(
            msg.sender,
            outcomeSlotIds,
            amounts
        );

        require(collateralToken.transfer(msg.sender, amount), "Could not send collateral tokens");

        emit MergeSuccess(msg.sender, collateralToken, marketId, amount);
    }

    /**
     * @dev For oracle to report market outcome after the market closing date.
     * @param questionId An identifier for the question to be answered by the oracle.
     * @param oracleOutcome The "correct" outcome report used to determine participant winnings.
     * oracleOutcome paramenter should be in same format as outcomeDetails[marketId]
     */
    function reportOutcome(bytes32 questionId, uint256 oracleOutcome) external {
        uint256 oracleOutcomeSlotCount = oracleOutcome % 16;
        require(oracleOutcomeSlotCount > 1, "There should be more than one outcome slot");

        // oracle is the outcome `msg.sender`
        bytes32 marketId = getMarketId(msg.sender, questionId, oracleOutcomeSlotCount);
        uint256 marketOutcomeSlotCount = outcomeDetails[marketId] % 16;
        require(marketOutcomeSlotCount > 1, "Market not prepared yet or is invalid");
        require(marketOutcomeSlotCount == oracleOutcomeSlotCount, "Oracle outcome slot count is incorrect");

        uint256 reportedOutcome = oracleOutcome >> 4;
        require(reportedOutcome > 0, "Oracle did not report any outcomes");
        // only allows oracles to successfully report outcomes once
        require(outcomeDetails[marketId] - marketOutcomeSlotCount == 0, "Oracle has already reported");

        outcomeDetails[marketId] += reportedOutcome << 4;

        emit OutcomeReportSucess(marketId, msg.sender, questionId, marketOutcomeSlotCount, reportedOutcome);
    }

    /**
     * @dev For market participant to redeem winnings if reported outcome matches the market token staked.
     * @param collateralToken The address of the backing collateral token.
     * @param marketId An identifier for the market to add liquidity to.
     */
    function redeemWinnings(
        IERC20 collateralToken,
        bytes32 marketId
    ) external {
        uint256 marketOutcomeSlotCount = outcomeDetails[marketId] % 16 ; // obtain last 4 bits
        require(marketOutcomeSlotCount > 1, "Market not prepared yet or is invalid");

        uint256 outcome = outcomeDetails[marketId] >> 4;
        require(outcome > 0, "Outcome has not been reported yet");
        
        uint256 numOfWinningOutcomes;
        uint256 totalWinningTokensAmount;
        uint256 totalPayout;

        for (uint8 i = 0; i < marketOutcomeSlotCount; i++) {
            if (outcome % 16 == 8) { // if last 4 bits are 1000 (i.e. outcome is correct)
                uint256 outcomeSlotId = getOutcomeSlotId(collateralToken, i, marketId);
                numOfWinningOutcomes += 1;

                uint256 winningTokenBalance = balanceOf(msg.sender, outcomeSlotId);
                if (winningTokenBalance > 0) {
                    totalWinningTokensAmount += winningTokenBalance;
                    _burn(msg.sender, outcomeSlotId, winningTokenBalance);
                }
            }
            outcome >>= 4;
        }

        if (totalWinningTokensAmount > 0) {
            // Each winning token value = 1 / numOfWinningOutcomes
            // totalPayout = totalWinningTokensAmount * (1 / numOfWinningOutcomes)
            totalPayout = totalWinningTokensAmount / numOfWinningOutcomes;
            require(collateralToken.transfer(msg.sender, totalPayout), "Could not transfer payout to message sender");
        }

        emit RedeemWinningsSuccess(msg.sender, collateralToken, marketId, totalPayout);
    }
}