// ConditionalTokens.sol
const MARKET_PREP_SUCCESS_ENCODE = 'MarketPrepSuccess(bytes32,address,bytes32,uint8)'
const MARKET_PREP_SUCCESS_TYPES = [
    { type: 'bytes32', name: 'conditionId' },
    { type: 'address', name: 'oracle' },
    { type: 'bytes32', name: 'questionId' },
    { type: 'uint8', name: 'outcomeSlotCount' }
]

const MINT_SUCCESS_ENCODE = 'MintSuccess(address,IERC20,bytes32,uint256)'
const MINT_SUCCESS_TYPES = [
    { type: 'address', name: 'stakeholder' },
    { type: 'IERC20', name: 'collateralToken' },
    { type: 'bytes32', name: 'marketId' },
    { type: 'uint256', name: 'amount' }
]

const MERGE_SUCCESS_ENCODE = 'MergeSuccess(address,IERC20,bytes32,uint256)'
const MERGE_SUCCESS_TYPES = [
    { type: 'address', name: 'stakeholder' },
    { type: 'IERC20', name: 'collateralToken' },
    { type: 'bytes32', name: 'marketId' },
    { type: 'uint256', name: 'amount' }
]

const OUTCOME_REPORT_SUCCESS_ENCODE = 'OutcomeReportSucess(bytes32,address,bytes32,uint8,uint8)'
const OUTCOME_REPORT_SUCCESS_TYPES = [
    { type: 'bytes32', name: 'marketId' },
    { type: 'address', name: 'oracle' },
    { type: 'bytes32', name: 'questionId' },
    { type: 'uint8', name: 'outcomeSlotCount' },
    { type: 'uint8', name: 'reportedOutcome' }
]

const REDEEM_WINNINGS_SUCCESS_ENCODE = 'RedeemWinningsSuccess(address,IERC20,bytes32,uint256)'
const REDEEM_WINNINGS_SUCCESS_TYPES = [
    { type: 'address', name: 'redeemer' },
    { type: 'IERC20', name: 'collateralToken' },
    { type: 'bytes32', name: 'marketId' },
    { type: 'uint256', name: 'totalPayout' }
]

const DUMMY_URI = 'https://mask.io/\{id}\.json'
const DUMMY_ORACLE = '0x67769430961F91D908aA6A9291d7d78D934c8e5a'
const DUMMY_QUESTION_ID = '0xdb81b4d58595fbbbb592d3661a34cdca14d7ab379441400cbfa1b78bc447c365'
const DUMMY_OUTCOME_SLOT_COUNT = 3

module.exports = {
    MARKET_PREP_SUCCESS_ENCODE,
    MARKET_PREP_SUCCESS_TYPES,
    MINT_SUCCESS_ENCODE,
    MINT_SUCCESS_TYPES,
    MERGE_SUCCESS_ENCODE,
    MERGE_SUCCESS_TYPES,
    OUTCOME_REPORT_SUCCESS_ENCODE,
    OUTCOME_REPORT_SUCCESS_TYPES,
    REDEEM_WINNINGS_SUCCESS_ENCODE,
    REDEEM_WINNINGS_SUCCESS_TYPES,
    DUMMY_URI,
    DUMMY_ORACLE,
    DUMMY_QUESTION_ID,
    DUMMY_OUTCOME_SLOT_COUNT
}