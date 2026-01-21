//
// Created by patryk on 12/27/25.

#ifndef MCTS_CHECKERS_BATCHEXECUTOR_CUH
#define MCTS_CHECKERS_BATCHEXECUTOR_CUH
#include <checkers/actions/actions.cuh>

#include "checkers/deviceResources/batchActionSpace.cuh"
#include "checkers/deviceResources/batchCheckerState.cuh"


struct MctsTocpuwbNode;

class BatchExecutor {
public:
    H void Test(size_t size, const BatchSoACheckersStateHost& batch, BatchLegalActionsHost& actions);
    //H void Run(size_t size, BatchSoACheckersState batch, BatchResults results);
    /**
     * Main function used in the mcts process, takes the one node which does not have any children yet
     * (only those can exist or with all children) finds ALL its children and performs simulation phase for
     * all of them in parallel, ALLOCATES children with simulated values and modifies the node to point at them
     */
    H static void ParallelFindChildrenAndSimulate(MctsTocpuwbNode* node);
private:
    H static void FindChildren(const BatchSoACheckersStateHost& batch, BatchLegalActionsHost& actions);
    H static void Expand(MctsTocpuwbNode *node, const BatchLegalActionsHost& children);
    H static void Simulate(size_t size, const BatchSoACheckersStateHost& batch, BatchSimulationResultsHost &results);
    H static void AssignRewards(MctsTocpuwbNode *node, BatchSimulationResultsHost &results);
};

GLOBAL void FindChildrenKernel(size_t batchSize, const BatchSoACheckersStateDevice *states, BatchLegalActionsDevice *actions);
GLOBAL void SimulateKernel(size_t batchSize, const BatchSoACheckersStateDevice *states, BatchLegalActionsDevice *actions, BatchSimulationResultsDevice* results);
#endif //MCTS_CHECKERS_BATCHEXECUTOR_CUH