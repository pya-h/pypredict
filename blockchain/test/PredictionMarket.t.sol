// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console} from "forge-std/Test.sol";
import {console} from 'forge-std/console.sol';
import {PredictionMarket} from "../src/PredictionMarket.sol";

contract PredictionMarketTest is Test {
    PredictionMarket private market;

    address oracle = address(0);
    address[] gamblers;
    uint16 public constant GAMBLERS_COUNT = 10;
    uint8 public constant GAMBLER_INITIAL_ETHERS = 10;

    function setUp() public {
        market = new PredictionMarket(oracle);
        for (uint160 i = 1; i <= GAMBLERS_COUNT; i++) {
            address g = address(i + 10);
            gamblers.push(g);
            deal(g, GAMBLER_INITIAL_ETHERS * (1 ether));
        }
    }

    function test_betOn() public {
        uint outcomesCount = market.numberOfOutcomes();
        uint maxInvestment = GAMBLER_INITIAL_ETHERS / 2;
        for (uint16 i = 0; i < gamblers.length; i++) {
            PredictionMarket.Outcome choice = PredictionMarket.Outcome(
                i % outcomesCount
            );
            uint numberOfBetsOnChoice = market.numberOfBetsOn(choice);
            uint totalBets = market.numberOfTotalBets();
            PredictionMarket.OutcomeBetStats memory initialStats = market
                .getSpecificOutcomeStatistics(choice);
            PredictionMarket.GamblerBetsStatus
                memory initialGamblerSelectedOutcomeStats = market
                    .getGamblerSpecificOutcomeBetsStatistics(
                        gamblers[i],
                        choice
                    );
            PredictionMarket.GamblerBetsStatus
                memory initialGamblerGeneralStats = market
                    .getGamblerGeneralStatistics(gamblers[i]);
            uint investAmount = (((block.timestamp * (i + 1)) % maxInvestment) +
                1) * 1 ether;
            vm.prank(gamblers[i]);
            market.betOn{value: investAmount}(choice);

            PredictionMarket.OutcomeBetStats memory newStats = market
                .getSpecificOutcomeStatistics(choice);
            PredictionMarket.GamblerBetsStatus
                memory newGamblerSelectedOutcomeStats = market
                    .getGamblerSpecificOutcomeBetsStatistics(
                        gamblers[i],
                        choice
                    );
            PredictionMarket.GamblerBetsStatus
                memory newGamblerGeneralStats = market
                    .getGamblerGeneralStatistics(gamblers[i]);
            assertEq(market.numberOfTotalBets(), totalBets + 1);
            assertEq(market.numberOfBetsOn(choice), numberOfBetsOnChoice + 1);
            assertEq(
                newStats.totalAmount,
                initialStats.totalAmount + investAmount
            );
            assertEq(newStats.count, initialStats.count + 1);
            assertEq(
                newGamblerSelectedOutcomeStats.investment,
                initialGamblerSelectedOutcomeStats.investment + investAmount
            );
            assertEq(
                newGamblerSelectedOutcomeStats.count,
                initialGamblerSelectedOutcomeStats.count + 1
            );
            assertEq(
                newGamblerGeneralStats.count,
                initialGamblerGeneralStats.count + 1
            );
            assertEq(
                newGamblerGeneralStats.investment,
                initialGamblerGeneralStats.investment + investAmount
            );
        }
    }

    function test_onMarketClosedBet() public {
        doResolve(oracle, 0, 100);
        uint outcomesCount = market.numberOfOutcomes();
        uint maxInvestment = GAMBLER_INITIAL_ETHERS / 2;
        for (uint16 i = 0; i < gamblers.length; i++) {
            PredictionMarket.Outcome choice = PredictionMarket.Outcome(
                (block.timestamp * i) % outcomesCount
            );
            uint numberOfBetsOnChoice = market.numberOfBetsOn(choice);
            uint totalBets = market.numberOfTotalBets();
            PredictionMarket.OutcomeBetStats memory initialStats = market
                .getSpecificOutcomeStatistics(choice);

            uint investAmount = ((maxInvestment % (i + 1)) + 1) * 1 ether;
            vm.prank(gamblers[i]);
            vm.expectRevert("Market is closed.");
            market.betOn{value: investAmount}(choice);

            // check nothing has changed
            PredictionMarket.OutcomeBetStats memory newStats = market
                .getSpecificOutcomeStatistics(choice);
            assertEq(market.numberOfTotalBets(), totalBets);
            assertEq(market.numberOfBetsOn(choice), numberOfBetsOnChoice);
            assertEq(newStats.totalAmount, initialStats.totalAmount);
            assertEq(newStats.count, initialStats.count);
        }
    }

    function doResolve(
        address oracleAddress,
        uint8 alphaTrueness,
        uint8 betaTrueness
    ) private {
        uint8[] memory trueness = new uint8[](2);
        trueness[0] = alphaTrueness;
        trueness[1] = betaTrueness;
        vm.prank(oracleAddress);
        market.resolve(trueness);
    }

    function test_resolve() public {
        uint8 randomTrueness = uint8(block.timestamp % 100);
        doResolve(oracle, randomTrueness, 100 - randomTrueness);
        assertEq(market.isOpen(), false);
        assertEq(
            market.getOutcomeTrueness(PredictionMarket.Outcome.Alpha),
            randomTrueness
        );
        assertEq(
            market.getOutcomeTrueness(PredictionMarket.Outcome.Beta),
            100 - randomTrueness
        );

        (PredictionMarket.Outcome firstChance, PredictionMarket.Outcome lastChance) = market.result();  // Solidity Destruction example
        assertEq(uint8(firstChance), uint8(randomTrueness >= 50 ? PredictionMarket.Outcome.Alpha : PredictionMarket.Outcome.Beta));
        assertEq(uint8(lastChance), uint8(randomTrueness < 50 ? PredictionMarket.Outcome.Alpha : PredictionMarket.Outcome.Beta));
    }

    function test_resolveByAnotherUser() public {
        vm.expectRevert("Only oracle is allowed to resolve this market.");
        doResolve(gamblers[block.timestamp % gamblers.length], 100, 0);
    }

    function test_resolveAResolvedMarket() public {
        doResolve(oracle, 100, 0);
        vm.expectRevert("Market has been resolved already.");
        doResolve(oracle, 100, 0);
    }

    function test_resolveForMoteThan2Outcomes() public {
        uint8 invalidOutcomeLength = uint8(block.timestamp % 10) + 2;
        uint8[] memory trueness = new uint8[](invalidOutcomeLength);
        trueness[0] = 100;
        for (uint i = 1; i < invalidOutcomeLength; i++) trueness[i] = 0;
        vm.expectRevert(
            "Oracle outcome set does not match with market outcomes."
        );
        vm.prank(oracle);
        market.resolve(trueness);
    }

    function test_resolveWithInvalidTrunessProbabilities() public {
        uint8 alpha = uint8(block.timestamp % 100);
        vm.expectRevert("Outcomes trueness array is invalid.");
        doResolve(
            oracle,
            alpha,
            100 - alpha + uint8(block.timestamp % 100) + 1
        );
    }

    function test_withdraw() public {
        uint256 outcomesCount = market.numberOfOutcomes();
        uint8 eachgamblerBets = uint8(block.timestamp % 3) + 2;
        uint256 maxInvestment = GAMBLER_INITIAL_ETHERS / eachgamblerBets;

        uint256[] memory alphaBets = new uint256[](gamblers.length);
        uint256[] memory betaBets = new uint256[](gamblers.length);
        uint256 alphaBetsSum = 0;
        uint256 betaBetsSum = 0;
        for (uint16 i = 0; i < gamblers.length; i++) {
            alphaBets[i] = 0;
            betaBets[i] = 0;
        }
        for (uint8 j = 0; j < eachgamblerBets; j++) {
            for (uint16 i = 0; i < gamblers.length; i++) {
                PredictionMarket.Outcome choice = PredictionMarket.Outcome(
                    (block.timestamp * i) % outcomesCount
                );
                uint256 investAmount = (((block.timestamp * (i + 1)) %
                    maxInvestment) + 1) * 1 ether;
                vm.prank(gamblers[i]);
                market.betOn{value: investAmount}(choice);
                if (choice == PredictionMarket.Outcome.Alpha) {
                    alphaBetsSum += investAmount;
                    alphaBets[i] += investAmount;
                } else {
                    betaBetsSum += investAmount;
                    betaBets[i] += investAmount;
                }
            }
        }
        uint8 alpha = uint8(block.timestamp % 2);
        doResolve(oracle, alpha * 100, (1 - alpha) * 100);
        uint256 awards = 0;
        for(uint256 i = 0; i < gamblers.length; i++) {
            uint256 initialBalance = gamblers[i].balance;
            uint256 gain = 0;

            if(alpha == 1) {
                gain = alphaBets[i] + uint256(alphaBets[i] * betaBetsSum / alphaBetsSum);
            } else {
                gain = betaBets[i] + uint256(betaBets[i] * alphaBetsSum / betaBetsSum);
            }

            vm.prank(gamblers[i]);
            market.withdraw();

            assertEq(gamblers[i].balance, initialBalance + gain);
            awards += gain;

            PredictionMarket.GamblerBetsStatus memory stats = market.getGamblerGeneralStatistics(gamblers[i]);
            assertEq(stats.count, 0);
            assertEq(stats.investment, 0);
        }
        uint256 marketLeftCharge = address(market).balance;
        assertLt(marketLeftCharge, 10); // It's natural to have some left offs due to division in solidity; but it needs to be small
        assertEq(alphaBetsSum + betaBetsSum, awards + marketLeftCharge);
    }

    function test_withdrawOnNoBet() public {
        doResolve(oracle, 100, 0);
        for (uint16 i = 0; i < gamblers.length; i++) {
            vm.expectRevert('You have not placed any bet yet.');
            vm.prank(gamblers[i]);
            market.withdraw();
        }
    }

    function test_withdrawOnMarketStillOpen() public {
        for (uint16 i = 0; i < gamblers.length; i++) {
            // place at least one bet to do not encounter 'no bet' error.
            vm.prank(gamblers[i]);
            market.betOn{value: 1 ether}(PredictionMarket.Outcome.Alpha);

            vm.expectRevert('Market is still open.');
            vm.prank(gamblers[i]);
            market.withdraw();
        }
    }

}
