// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console} from "forge-std/Test.sol";
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
            address g = address(i);
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
            uint investAmount = (((block.timestamp * (i + 1)) % maxInvestment) + 1) * 1 ether;
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
        uint outcomesCount = market.numberOfOutcomes();
        uint8 eachgamblerBets = uint8(block.timestamp % 3) + 2;
        uint maxInvestment = GAMBLER_INITIAL_ETHERS / eachgamblerBets;

        uint256[] memory alphaBets = new uint256[](gamblers.length);
        uint256[] memory betaBets = new uint256[](gamblers.length);

        for (uint16 i = 0; i < gamblers.length; i++) {
            alphaBets[i] = 0;
            betaBets[i] = 0;
        }
        for (uint8 j = 0; j < eachgamblerBets; j++) {
            for (uint16 i = 0; i < gamblers.length; i++) {
                PredictionMarket.Outcome choice = PredictionMarket.Outcome(
                    (block.timestamp * i) % outcomesCount
                );
                uint investAmount = (((block.timestamp * (i + 1)) % maxInvestment) + 1) * 1 ether;
                vm.prank(gamblers[i]);
                market.betOn{value: investAmount}(choice);
                if (choice == PredictionMarket.Outcome.Alpha) {
                    alphaBets[i] += investAmount;
                } else {
                    betaBets[i] += investAmount;
                }
            }
        }
    }
}
