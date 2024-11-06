.PHONY: test deploy report

test :; forge test --match-path test/PredictionMarket.t.sol

test+ :; forge test --match-path test/PredictionMarket.t.sol -vvvv

deploy :; forge script script/PredictionMarket.s.sol:DeployScript --broadcast --rpc-url http://127.0.0.1:8545

resolve :; forge script script/PredictionMarket.s.sol:ResolveScript --broadcast --rpc-url http://127.0.0.1:8545
