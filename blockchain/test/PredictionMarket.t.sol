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
            vm.prank(gamblers[i]);
            PredictionMarket.Outcome choice = PredictionMarket.Outcome(i % outcomesCount);
            uint numberOfBetsOnChoice = market.numberOfBetsOn(choice);
            uint totalBets = market.numberOfTotalBets();
            PredictionMarket.OutcomeBetStats memory initialStats = market.getSpecificOutcomeStatistics(choice);
            uint investAmount = ((maxInvestment % (i+1)) + 1) * 1 ether;
            
            market.betOn{value: investAmount}(choice);

            PredictionMarket.OutcomeBetStats memory newStats = market.getSpecificOutcomeStatistics(choice);
            assertEq(market.numberOfTotalBets(), totalBets + 1);
            assertEq(market.numberOfBetsOn(choice), numberOfBetsOnChoice + 1);
            assertEq(newStats.totalAmount, initialStats.totalAmount + investAmount);
            assertEq(newStats.count, initialStats.count + 1);

            // TODO: Also test some other values & states.
        }
    }
}
