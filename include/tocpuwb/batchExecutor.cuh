//
// Created by patryk on 12/27/25.

#ifndef MCTS_CHECKERS_BATCHEXECUTOR_CUH
#define MCTS_CHECKERS_BATCHEXECUTOR_CUH
#include <checkers/actions/actions.cuh>

#include "checkers/deviceResources/batchActionSpace.cuh"
#include "checkers/deviceResources/batchCheckerState.cuh"


class BatchExecutor {
public:
    H void Test(size_t size, const BatchSoACheckersStateHost& batch, BatchLegalActionsHost& actions);
    //H void Run(size_t size, BatchSoACheckersState batch, BatchResults results);
};

#endif //MCTS_CHECKERS_BATCHEXECUTOR_CUH