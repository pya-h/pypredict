// SPDX-License-Identifier: MIT 
pragma solidity ^0.8.13;

import {Script} from "forge-std/Script.sol";
import {PredictionMarket} from "../src/PredictionMarket.sol";

contract DeployScript is Script {
    PredictionMarket private market;

    uint private deployerPrivateKey = 0x59c6995e998f97a5a0044966f0945389dc9e86dae88c7a8412f4603b6b78690d;
    uint[] private gamblersPrivateKeys = [
        0x7c852118294e51e653712a81e05800f419141751be58f605c371e15141b007a6,
        0x7c852118294e51e653712a81e05800f419141751be58f605c371e15141b007a6,
        0x4bbbf85ce3377467afe5d46f804f221813b2bb87f24d81f60f1fcdbf7cbf4356,
        0xdbda1821b80551c9d65939329250298aa3472ba22feea921c0cf5d620ea67b97,
        0x2a871d0798f97d79848a013d4936a73bf4cc922c825d33c1cf7073dff6d409c6
    ];

    function setUp() public {}

    function run() public {
        vm.startBroadcast(deployerPrivateKey);
        market = new PredictionMarket(vm.addr(deployerPrivateKey));
        vm.stopBroadcast();

        uint outcomesCount = market.numberOfOutcomes();
        uint maxInvestment = 10;
        for (uint16 i = 0; i < gamblersPrivateKeys.length; i++) {
            PredictionMarket.Outcome choice = PredictionMarket.Outcome(
                i % outcomesCount
            );
            uint investAmount = (((block.timestamp * (i + 1)) % maxInvestment) +
                1) * 1 ether;
            vm.startBroadcast(gamblersPrivateKeys[i]);
            market.betOn{value: investAmount}(choice);
            vm.stopBroadcast();
        }
    }
}


contract ResolveScript is Script {
    function setUp() public {}

    // PredicitionMarket private market;

    function run() public {
        uint deployerPrivate = 0x59c6995e998f97a5a0044966f0945389dc9e86dae88c7a8412f4603b6b78690d;
    }
}