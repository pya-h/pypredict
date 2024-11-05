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
        for(uint160 i = 1; i <= GAMBLERS_COUNT; i++) {
            address g = address(i);
            gamblers.push(g);
            deal(g, GAMBLER_INITIAL_ETHERS * (1 ether));
        }

    }

    function test_betOn() public {
        uint outcomesCount = market.numberOfOutcomes();
        uint maxInvestment = GAMBLER_INITIAL_ETHERS / 2;
        for(uint16 i = 0; i < gamblers.length; i++) {
            PredictionMarket.Outcome choice = PredictionMarket.Outcome(i % outcomesCount);
            uint numberOfBetsOnChoice = market.numberOfBetsOn(choice);
            uint totalBets = market.numberOfTotalBets();
            PredictionMarket.OutcomeBetStats memory initialStats = market.getSpecificOutcomeStatistics(choice);
            PredictionMarket.GamblerBetsStatus memory initialGamblerSelectedOutcomeStats = market.getGamblerSpecificOutcomeBetsStatistics(gamblers[i], choice);
            PredictionMarket.GamblerBetsStatus memory initialGamblerGeneralStats = market.getGamblerGeneralStatistics(gamblers[i]);
            uint investAmount = ((maxInvestment % (i+1)) + 1) * 1 ether;
            vm.prank(gamblers[i]);
            market.betOn{value: investAmount}(choice);

            PredictionMarket.OutcomeBetStats memory newStats = market.getSpecificOutcomeStatistics(choice);
            PredictionMarket.GamblerBetsStatus memory newGamblerSelectedOutcomeStats = market.getGamblerSpecificOutcomeBetsStatistics(gamblers[i], choice);
            PredictionMarket.GamblerBetsStatus memory newGamblerGeneralStats = market.getGamblerGeneralStatistics(gamblers[i]);
            assertEq(market.numberOfTotalBets(), totalBets + 1);
            assertEq(market.numberOfBetsOn(choice), numberOfBetsOnChoice + 1);
            assertEq(newStats.totalAmount, initialStats.totalAmount + investAmount);
            assertEq(newStats.count, initialStats.count + 1);
            assertEq(newGamblerSelectedOutcomeStats.investment, initialGamblerSelectedOutcomeStats.investment + investAmount);
            assertEq(newGamblerSelectedOutcomeStats.count, initialGamblerSelectedOutcomeStats.count + 1);
            assertEq(newGamblerGeneralStats.count, initialGamblerGeneralStats.count + 1);
            assertEq(newGamblerGeneralStats.investment, initialGamblerGeneralStats.investment + investAmount);
        }
    }

    function test_onMarketClosedBet() public {
        vm.prank(oracle);
        uint8[] memory trueness = new uint8[](2);
        trueness[0] = 0; trueness[1] = 100;
        market.resolve(trueness);
        uint outcomesCount = market.numberOfOutcomes();
        uint maxInvestment = GAMBLER_INITIAL_ETHERS / 2;
        for(uint16 i = 0; i < gamblers.length; i++) {
            PredictionMarket.Outcome choice = PredictionMarket.Outcome(i % outcomesCount);
            uint numberOfBetsOnChoice = market.numberOfBetsOn(choice);
            uint totalBets = market.numberOfTotalBets();
            PredictionMarket.OutcomeBetStats memory initialStats = market.getSpecificOutcomeStatistics(choice);

            uint investAmount = ((maxInvestment % (i+1)) + 1) * 1 ether;
            vm.prank(gamblers[i]);
            vm.expectRevert('Market is closed.');
            market.betOn{value: investAmount}(choice);

            // check nothing has changed
            PredictionMarket.OutcomeBetStats memory newStats = market.getSpecificOutcomeStatistics(choice);
            assertEq(market.numberOfTotalBets(), totalBets);
            assertEq(market.numberOfBetsOn(choice), numberOfBetsOnChoice);
            assertEq(newStats.totalAmount, initialStats.totalAmount);
            assertEq(newStats.count, initialStats.count);
        }
    }
}
