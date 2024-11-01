pragma solidity 0.8.28;

contract PredictionMarket {
    enum Outcome {
        Alpha,
        Beta
    }
    uint256 idOffset = 0;
    struct Bet {
        uint256 id;
        address gambler;
        uint256 amount;
        // address     token;   //TODO:
        Outcome on;
    }

    struct OutcomeBetStats {
        uint256 count;
        uint256 totalAmount;
    }

    address oracle;
    uint256 public finishedAt; // epoch time
    mapping(Outcome => uint8) public trueness;
    mapping(Outcome => Bet[]) public bets;
    mapping(address => uint256) public investmentsPerGamblers;

    constructor(address _oracleAddress) {
        oracle = _oracleAddress;
    }

    function betOn(Outcome choice) external payable {
        require(finishedAt > 0, "Market closed.");
        bets[choice].push(Bet(++idOffset, msg.sender, msg.value, choice));
        if (investmentsPerGamblers[msg.sender] == 0) {
            investmentsPerGamblers[msg.sender] = msg.value;
        } else {
            investmentsPerGamblers[msg.sender] += msg.value;
        }
    }

    function outcomeCurrentStatistics(
        Outcome outcome
    ) external view returns (OutcomeBetStats memory) {
        uint256 totalAmount = 0;
        OutcomeBetStats memory stats = OutcomeBetStats(bets[outcome].length, 0);

        for (uint256 i = 0; i < bets[outcome].length; i++) {
            totalAmount += bets[outcome][i].amount;
        }
        return stats;
    }
}
