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
        uint256 investment;
    }

    Outcome[] public allOutcomes = [Outcome.Alpha, Outcome.Beta];
    address oracle;
    uint256 public finishedAt; // epoch time
    mapping(Outcome => uint8) public trueness;
    mapping(Outcome => Bet[]) public bets;

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
    }

    /**
     * Gives general statistics regrading a specific outcome
     * @param outcome: Outcome.Alpha | Outcome.Beta
     */
    function getSpecificOutcomeStatistics(
        Outcome outcome
    ) external view returns (OutcomeBetStats memory) {
        OutcomeBetStats memory stats = OutcomeBetStats(bets[outcome].length, 0);

        for (uint256 i = 0; i < bets[outcome].length; i++) {
            stats.totalAmount += bets[outcome][i].amount;
        }
        return stats;
    }

    /**
     * This function returns the statistics regarding an specific gambler (user)
     * @param gambler : wallet address of the user getting its stats.
     */
    function getGamblerBinaryBetStatistics(
        address gambler
    ) external view returns (GamblerBetsStatus memory) {
        GamblerBetsStatus memory stats = GamblerBetsStatus(gambler, 0, 0);

        (uint256 minLength, Outcome popular) = bets[Outcome.Alpha].length <=
            bets[Outcome.Beta].length
            ? (bets[Outcome.Alpha].length, Outcome.Beta)
            : (bets[Outcome.Beta].length, Outcome.Alpha);

        // instead of
        for (uint256 i = 0; i < minLength; i++) {
            if (bets[Outcome.Alpha][i].gambler == gambler) {
                stats.count++;
                stats.investment += bets[Outcome.Alpha][i].amount;
            }
            if (bets[Outcome.Beta][i].gambler == gambler) {
                stats.count++;
                stats.investment += bets[Outcome.Beta][i].amount;
            }
        }

        for (uint256 i = minLength; i < bets[popular].length; i++) {
            if (bets[popular][i].gambler == gambler) {
                stats.count++;
                stats.investment += bets[popular][i].amount;
            }
        }

        return stats;
    }

    /**
     * This function returns the statistics regarding an specific gambler bets on a specific outcome gamblerCurrentBinaryBetStatistics,
     *  but it is a general form fr any number of outcomes in the market [the former only supports two outcome[]]
     * @param gambler : wallet address of the user getting its stats.
     */
    function getGamblerSpecificOutcomeBetsStatistics(
        address gambler,
        Outcome outcome
    ) external view returns (GamblerBetsStatus memory) {
        GamblerBetsStatus memory stats = GamblerBetsStatus(gambler, 0, 0);

        for (uint256 i = 0; i < bets[outcome].length; i++) {
            if (bets[outcome][i].gambler == gambler) {
                stats.count++;
                stats.investment += bets[outcome][i].amount;
            }
        }

        return stats;
    }

    /**
     * This function returns the statistics regarding an specific gambler bets on a specific outcome, though this not as enhanced as the
     * @param gambler : wallet address of the user getting its stats.
     */
    function getGamblerGeneralStatistics(
        address gambler
    ) external view returns (GamblerBetsStatus memory) {
        GamblerBetsStatus memory stats = GamblerBetsStatus(gambler, 0, 0);

        for (uint256 j = 0; j < allOutcomes.length; j++) {
            for (uint256 i = 0; i < bets[allOutcomes[j]].length; i++) {
                if (bets[allOutcomes[j]][i].gambler == gambler) {
                    stats.count++;
                    stats.investment += bets[allOutcomes[i]][i].amount;
                }
            }
        }
        return stats;
    }
}
