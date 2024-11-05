// SPDX-License-Identifier: MIT
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
        bool withdrew;
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

    Outcome[] private allOutcomes = [Outcome.Alpha, Outcome.Beta];
    address oracle;
    uint256 private finishedAt; // epoch time
    mapping(Outcome => uint8) private trueness;
    mapping(Outcome => Bet[]) private bets;

    constructor(address _oracleAddress) {
        oracle = _oracleAddress;
        finishedAt = 0;
    }

    function isOpen() external view returns (bool) {
        return finishedAt == 0;
    }

    function numberOfBetsOn(Outcome outcome) external view returns (uint256) {
        return bets[outcome].length;
    }

    function numberOfTotalBets() external view returns (uint256) {
        uint256 count = 0;
        for (uint i = 0; i < allOutcomes.length; i++) {
            count += bets[allOutcomes[i]].length;
        }
        return count;
    }

    function numberOfOutcomes() public view returns (uint256) {
        return allOutcomes.length;
    }

    /**
     * Allows a gambler to bet specific amount of ethers on an outcome
     * @param choice: Outcome.Alpha | Outcome.Beta
     */
    function betOn(Outcome choice) external payable {
        require(finishedAt == 0, "Market is closed.");
        bets[choice].push(
            Bet(++idOffset, msg.sender, msg.value, choice, false)
        );
    }

    /**
     * Gives general statistics regrading a specific outcome
     * @param outcome: Outcome.Alpha | Outcome.Beta
     */
    function getSpecificOutcomeStatistics(
        Outcome outcome
    ) public view returns (OutcomeBetStats memory) {
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
    ) public view returns (GamblerBetsStatus memory) {
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
    ) public view returns (GamblerBetsStatus memory) {
        GamblerBetsStatus memory stats = GamblerBetsStatus(gambler, 0, 0);

        for (uint256 i = 0; i < bets[outcome].length; i++) {
            if (
                bets[outcome][i].gambler == gambler &&
                !bets[outcome][i].withdrew
            ) {
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
    ) public view returns (GamblerBetsStatus memory) {
        GamblerBetsStatus memory stats = GamblerBetsStatus(gambler, 0, 0);

        for (uint256 j = 0; j < allOutcomes.length; j++) {
            for (uint256 i = 0; i < bets[allOutcomes[j]].length; i++) {
                if (
                    bets[allOutcomes[j]][i].gambler == gambler &&
                    !bets[allOutcomes[j]][i].withdrew
                ) {
                    stats.count++;
                    stats.investment += bets[allOutcomes[j]][i].amount;
                }
            }
        }
        return stats;
    }

    function markBetsAsWithdrew(address gambler) private {
        for (uint256 j = 0; j < allOutcomes.length; j++) {
            for (uint256 i = 0; i < bets[allOutcomes[j]].length; i++) {
                if (
                    bets[allOutcomes[j]][i].gambler == gambler &&
                    !bets[allOutcomes[j]][i].withdrew
                ) {
                    bets[allOutcomes[j]][i].withdrew = true;
                }
            }
        }
    }

    function withdraw() external {
        require(finishedAt > 0, "Prediction is not finished yet...");
        uint256 gains = 0;
        uint256 gamblerTrueInvestments = 0;
        uint256 totalTrueOutcomeInvestments = 0;
        uint256 totalFalseOutcomeInvestments = 0;
        for (uint i = 0; i < allOutcomes.length; i++) {
            Outcome outcome = allOutcomes[i];
            uint256 investedOnOutcome = getSpecificOutcomeStatistics(outcome)
                .totalAmount;
            if (trueness[outcome] > 0) {
                totalTrueOutcomeInvestments += investedOnOutcome;
                GamblerBetsStatus
                    memory betStats = getGamblerSpecificOutcomeBetsStatistics(
                        msg.sender,
                        outcome
                    );
                if (betStats.investment > 0) {
                    gamblerTrueInvestments +=
                        (trueness[outcome] * betStats.investment) /
                        100;
                }
            } else {
                totalFalseOutcomeInvestments += investedOnOutcome;
            }
        }
        require(
            gamblerTrueInvestments > 0,
            "You have not invested on a correct outcome."
        );
        gains +=
            (totalFalseOutcomeInvestments * gamblerTrueInvestments) /
            totalTrueOutcomeInvestments;
        (bool success, ) = payable(msg.sender).call{
            value: gains + gamblerTrueInvestments
        }("");
        require(success, "Withdrawal failed.");
        // FIXME: Checkout the math logic here.

        markBetsAsWithdrew(msg.sender);
    }

    function resolve(uint8[] memory outcomeTrueness) external {
        require(
            msg.sender == oracle,
            "Only oracle is allowed to resolve this market."
        );
        require(finishedAt == 0, "Market has been resolved already.");
        require(
            outcomeTrueness.length == allOutcomes.length,
            "Oracle outcome set does not match with market outcomes."
        );
        uint outcomesSum = 0;
        for (uint i = 0; i < outcomeTrueness.length; i++) {
            outcomesSum += outcomeTrueness[i];
        }
        require(outcomesSum == 100, "Outcomes trueness array is invalid.");

        for (uint i = 0; i < outcomeTrueness.length; i++) {
            trueness[Outcome(i)] = outcomeTrueness[i];
        }

        finishedAt = block.timestamp;
    }

    function getOutcomeTrueness(Outcome outcome) public view returns (uint8) {
        require(finishedAt > 0, "Market due not reached yet.");
        return trueness[outcome];
    }
}
