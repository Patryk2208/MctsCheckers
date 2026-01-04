//
// Created by patryk on 12/19/25.
//

#include "tocpuwb/batchExecutor.cuh"

int main() {
    auto batchSize = 1;
    auto executor = BatchExecutor{};
    auto batchActions = BatchLegalActionsHost(batchSize);
    /*auto testState = CheckersState
    {
        0b00000000000000000000111111111111,
        0b11111111111100000000000000000000,
        0,
        0,
        0xa0
    };*/
    /*auto testState = CheckersState
    {
        0b00000000000000000100101111111111,
        0b11111111110101000000000000000000,
        0,
        0,
        0x00
    };*/
    /*auto testState = CheckersState
    {
        0b00000000000000001000000000001110,
        0b00000001000000010010001000000000,
        0b01000000000000000000000000000000,
        0,
        0x00
    };*/
    auto testState = CheckersState
    {
        0b00000000100000000000000000000101,
        0b00001000000100000011000000010000,
        0b00000000000001000000000000000000,
        0b00000000000000000000100000000000,
        0x6
    };
    auto states = std::vector{testState};
    auto batchStates = BatchSoACheckersStateHost(states);
    executor.Test(batchSize, batchStates, batchActions);
}