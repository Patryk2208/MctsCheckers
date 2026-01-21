//
// Created by patryk on 12/27/25.
//

#include "tocpuwb/batchExecutor.cuh"

#include <bitset>
#include <iostream>

#include "tocpuwb/tree.hpp"


void BatchExecutor::Test(const size_t size, const BatchSoACheckersStateHost& batch, BatchLegalActionsHost& actions) {
    /*unsigned *a, *res = new unsigned[4];
    int input = 31;
    CUDA_CHECK(cudaMalloc(&a, 4 * sizeof(unsigned)));
    testDirectionFunctions<<<1, 4>>>(input, a);
    CUDA_CHECK(cudaMemcpy(res, a, 4 * sizeof(unsigned), cudaMemcpyDeviceToHost));
    printf("%u -> [%u, %u, %u, %u]\n", input, res[0], res[1], res[2], res[3]);
    delete[] res;
    return;*/
    //TestTest();
    //return;

    BatchSoACheckersStateResource d_batch(batch, size);
    BatchLegalActionsResource d_actions(size);

    const auto gridSize = 1;
    const auto blockSize = 32;
    const auto shmSize = size * SharedMemorySize;
    GetLegalActions<<<gridSize, blockSize, shmSize>>>(nullptr, size, d_batch.self_.get(), d_actions.self_.get());
    KERNEL_CHECK();
    actions.CopyFromGpu(d_actions);
    for (auto i = 0; i < size; i++) {
        std::cout << "Result for board " << i << ":: " << std::endl;
        for (auto j = 0; j < actions.actions_[i].size_; j++) {
            std::cout << std::bitset<32>(actions.actions_[i].buffer_[j].whitePawns_) << " " <<
                std::bitset<32>(actions.actions_[i].buffer_[j].whiteQueens_) << " " <<
                std::bitset<32>(actions.actions_[i].buffer_[j].blackPawns_) << " " <<
                std::bitset<32>(actions.actions_[i].buffer_[j].blackQueens_) << " " <<
                std::bitset<32>(actions.actions_[i].buffer_[j].metadata_) << std::endl;
        }
        std::cout << std::endl;
    }
}


/**
 * First in the selection process we get the node that has no children, so naturally we need to find those,
 * we call GetAllLegalActions and obtain children count and those states
 * Expansion: Having that data we can expand the tree adding each child to the node
 * Simulations: Then for each child, we take all their states and call a simulation kernel, which does many
 * parallel different simulations for the same state and also the crucial GetLegalActions function is also
 * parallelized, then when the results come, we assign reward_ to each child and finish
 */
void BatchExecutor::ParallelFindChildrenAndSimulate(MctsTocpuwbNode *node) {
    auto nodeSingleBatch = BatchSoACheckersStateHost({node->state_});
    auto actions = BatchLegalActionsHost(1);
    FindChildren(nodeSingleBatch, actions);
    Expand(node, actions);
    //simulate
    //assigning calculated reward
}

void BatchExecutor::FindChildren(const BatchSoACheckersStateHost& batch, BatchLegalActionsHost& actions) {
    constexpr auto size = 1;
    BatchSoACheckersStateResource d_batch(batch, size);
    BatchLegalActionsResource d_actions(size);
    constexpr auto gridSize = size;
    constexpr auto blockSize = 32;
    constexpr auto shmSize = size * SharedMemorySize;
    FindChildrenKernel<<<gridSize, blockSize, shmSize>>>(size, d_batch.self_.get(), d_actions.self_.get());
    KERNEL_CHECK();
    actions.CopyFromGpu(d_actions);
}

GLOBAL void FindChildrenKernel(size_t batchSize, const BatchSoACheckersStateDevice *states, BatchLegalActionsDevice *actions) {
    extern __shared__ char shm[];
    GetLegalActions(shm, batchSize, states, actions);
}


void BatchExecutor::Expand(MctsTocpuwbNode *node, const BatchLegalActionsHost &children) {
    auto childrenForNode = children.actions_[0];
    node->childrenCount_ = childrenForNode.size_;
    node->children_ = new MctsTocpuwbNode[node->childrenCount_];
    for (auto i = 0; i < node->childrenCount_; i++) {
        auto* const child = &node->children_[i];
        child->parent_ = node;
        child->children_ = nullptr;
        child->childrenCount_ = 0;
        child->state_ = childrenForNode.buffer_[i];
        child->reward_ = 0.0f;
        child->visitCount_ = 1.0f; //todo
    }
}

void BatchExecutor::Simulate(size_t size, const BatchSoACheckersStateHost &batch, BatchSimulationResultsHost &results) {
    //todo simulation copying
}

GLOBAL void SimulateKernel(size_t batchSize, const BatchSoACheckersStateDevice *states, BatchLegalActionsDevice *actions, BatchSimulationResultsDevice* results) {
    extern __shared__ char shm[];
    //todo
}

void BatchExecutor::AssignRewards(MctsTocpuwbNode *node, BatchSimulationResultsHost &results) {
    //todo determine the exact results form
}

