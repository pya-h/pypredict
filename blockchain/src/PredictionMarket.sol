pragma solidity 0.8.26;

contract PredictionMarket {
    enum Outcome {
        Alpha,
        Beta
    }

    struct Bet {
        gambler address
        amount  uint256
        token   address
        on      Outcome
    }

    address oracle;
    mapping(Outcome => uint8) public trueness;
    uint256 public finishedAt; // epoch time

    mapping(Outcome => Bet[]) public bets;

    constructor(address _oracleAddress) {
        oracle = _oracleAddress
    }

    function betOn(Outcome choice) external payable {
        require(finishedAt > 0, "Market closed.");
        
    }
}