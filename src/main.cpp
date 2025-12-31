//
// Created by patryk on 12/19/25.
//

#include "tocpuwb/batchExecutor.cuh"

int main() {
    auto batchSize = 1;
    auto executor = BatchExecutor{};
    auto batchActions = BatchLegalActions{};
    auto testState = CheckersState
    {
        0b00000000000000000000111111111111,
        0b11111111111100000000000000000000,
        0,
        0,
        0
    };
    auto states = std::vector{testState};
    auto batchStates = BatchSoACheckersState(states);
    executor.Test(batchSize, batchStates, batchActions);
}