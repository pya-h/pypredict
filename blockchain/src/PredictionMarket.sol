pragma solidity 0.8.28;

contract PredictionMarket {
    enum Outcome {
        Alpha, // [Based on th question alpha & beta will be shown with a specific title in front (or returned from backend or whatever.])
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

    struct GamblerBetsStatus {
        address gambler;
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

    /**
     * Allows a gambler to bet specific amount of ethers on an outcome
     * @param choice: Outcome.Alpha | Outcome.Beta
     */
    function betOn(Outcome choice) external payable {
        require(finishedAt > 0, "Market closed.");
        bets[choice].push(Bet(++idOffset, msg.sender, msg.value, choice));
        if (investmentsPerGamblers[msg.sender] == 0) {
            investmentsPerGamblers[msg.sender] = msg.value;
        } else {
            investmentsPerGamblers[msg.sender] += msg.value;
        }
    }

    /**
     * Gives general statistics regrading a specific outcome
     * @param outcome: Outcome.Alpha | Outcome.Beta
     */
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

    /**
     * This function returns the statistics regarding an specific gambler (user)
     * @param gambler : wallet address of the user getting its stats.
     */
    function gamblerCurrentStatistics(
        address gambler
    ) external view returns (GamblerBetsStatus memory) {
        GamblerBetsStatus memory stats = GamblerBetsStatus(
            gambler,
            0,
            investmentsPerGamblers[gambler]
        );

        (uint256 minLength, Outcome popular) = bets[Outcome.Alpha].length <=
            bets[Outcome.Beta].length
            ? (bets[Outcome.Alpha].length, Outcome.Beta)
            : (bets[Outcome.Beta].length, Outcome.Alpha);

        for (uint256 i = 0; i < minLength; i++) {
            if (bets[Outcome.Alpha][i].gambler == gambler) {
                stats.count++;
            }
            if (bets[Outcome.Beta][i].gambler == gambler) {
                stats.count++;
            }
        }

        for (uint256 i = minLength; i < bets[popular].length; i++) {
            if (bets[popular][i].gambler == gambler) {
                stats.count++;
            }
        }

        return stats;
    }
}
