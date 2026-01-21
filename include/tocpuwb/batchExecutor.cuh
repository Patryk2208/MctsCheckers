//
// Created by patryk on 12/27/25.

#ifndef MCTS_CHECKERS_BATCHEXECUTOR_CUH
#define MCTS_CHECKERS_BATCHEXECUTOR_CUH

#include "tocpuwb/tree.hpp"
#include "checkers/deviceResources/batchActionSpace.cuh"
#include "checkers/deviceResources/batchCheckerState.cuh"
#include "checkers/actions/actions.cuh"

#include <bitset>
#include <iostream>
#include <curand_kernel.h>


struct MctsTocpuwbNode;

class BatchExecutor {
    int leafParallelismFactor_;
public:
    BatchExecutor(int leafParallelismFactor) : leafParallelismFactor_(leafParallelismFactor) {}
    H void Test(size_t size, const BatchSoACheckersStateHost& batch, BatchLegalActionsHost& actions);
    //H void Run(size_t size, BatchSoACheckersState batch, BatchResults results);
    /**
     * Main function used in the mcts process, takes the one node which does not have any children yet
     * (only those can exist or with all children) finds ALL its children and performs simulation phase for
     * all of them in parallel, ALLOCATES children with simulated values and modifies the node to point at them
     */
    H void ParallelFindChildrenAndSimulate(MctsTocpuwbNode *node, unsigned long long seed);
private:
    H void InitializeRandomness(size_t batchSize, curandState* randomStates, unsigned long long seed);
    H void FindChildren(const BatchSoACheckersStateHost& h_batch, const BatchLegalActionsHost& h_actions);
    H void Expand(MctsTocpuwbNode *node, const BatchLegalActionsHost& h_children);
    H void Simulate(size_t batchSize, curandState* randomStates, const BatchSoACheckersStateHost& h_batch, BatchSimulationResultsHost &h_results);
    H void AssignRewards(const MctsTocpuwbNode *node, const BatchSimulationResultsHost &h_results);
};

GLOBAL void InitializeRandomnessKernel(size_t size, curandState* randomStates, unsigned long long seed);
GLOBAL void FindChildrenKernel(size_t batchSize, const BatchSoACheckersStateDevice *d_states, BatchLegalActionsDevice *d_actions);
GLOBAL void SimulateKernel(size_t batchSize, curandState* randomStates, const BatchSoACheckersStateDevice *states, BatchLegalActionsDevice *actions, BatchSimulationResultsDevice* results);
#endif //MCTS_CHECKERS_BATCHEXECUTOR_CUH