certoraRun certora/harness/ProofOfReserveExecutorV2Harness.sol certora/harness/PORaggregatorDummy.sol \
    --verify ProofOfReserveExecutorV2Harness:certora/specs/executorV2.spec \
    --link ProofOfReserveExecutorV2Harness:_proofOfReserveAggregator=PORaggregatorDummy \
    --solc solc8.16 \
    --optimistic_loop \
    --loop_iter 3 \
    --msg "ProofOfReserveExecutorV2 sanity" \
    --staging abakst/static-array-memcopy-loops \
    --packages solidity-utils=lib/solidity-utils/src chainlink-brownie-contracts=lib/chainlink-brownie-contracts/contracts/src/v0.8/ aave-address-book=lib/aave-address-book/src/ forge-std=lib/forge-std/src/ 
    