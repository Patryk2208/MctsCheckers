//
// Created by patryk on 12/27/25.
//

#include "tocpuwb/batchExecutor.cuh"


/*
void BatchExecutor::Test(const size_t size, const BatchSoACheckersStateHost& batch, BatchLegalActionsHost& actions) {
    /*unsigned *a, *res = new unsigned[4];
    int input = 31;
    CUDA_CHECK(cudaMalloc(&a, 4 * sizeof(unsigned)));
    testDirectionFunctions<<<1, 4>>>(input, a);
    CUDA_CHECK(cudaMemcpy(res, a, 4 * sizeof(unsigned), cudaMemcpyDeviceToHost));
    printf("%u -> [%u, %u, %u, %u]\n", input, res[0], res[1], res[2], res[3]);
    delete[] res;
    return;#1#
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
*/


/**
 * First in the selection process we get the node that has no children, so naturally we need to find those,
 * we call GetAllLegalActions and obtain children count and those states
 * Expansion: Having that data we can expand the tree adding each child to the node
 * Simulations: Then for each child, we take all their states and call a simulation kernel, which does many
 * parallel different simulations for the same state and also the crucial GetLegalActions function is also
 * parallelized, then when the results come, we assign reward_ to each child and finish
 */
void BatchExecutor::ParallelFindChildrenAndSimulate(MctsTocpuwbNode *node, const unsigned long long seed) {
    const auto h_nodeSingleBatch = BatchSoACheckersStateHost({node->state_});
    auto h_actions = BatchLegalActionsHost(1);
    FindChildren(h_nodeSingleBatch, h_actions);

    Expand(node, h_actions);

    const auto batchSize = node->childrenCount_ * leafParallelismFactor_;
    CudaResource<curandState> r_randomStates(batchSize);
    InitializeRandomness(batchSize, r_randomStates.get(), seed);
    auto leafParallelStates = std::vector<CheckersState>(batchSize);
    for (int i = 0; i < node->childrenCount_; i++) {
        for (auto j = 0; j < leafParallelismFactor_; j++) {
            leafParallelStates[i * leafParallelismFactor_ + j] = node->children_[i].state_;
        }
    }
    const auto h_batch = BatchSoACheckersStateHost(leafParallelStates);
    auto h_results = BatchSimulationResultsHost(batchSize);
    Simulate(batchSize, r_randomStates.get(), h_batch, h_results);

    AssignRewards(node, h_results);
}

void BatchExecutor::InitializeRandomness(const size_t batchSize, curandState* randomStates, const unsigned long long seed) {
    constexpr auto threadsPerState = 32;
    const auto stateCount = batchSize;
    const auto totalStates = threadsPerState * stateCount;
    constexpr auto blockSize = 512;
    const auto gridSize = (totalStates + blockSize - 1) / blockSize;
    InitializeRandomnessKernel<<<gridSize, blockSize>>>(batchSize, randomStates, seed);
    KERNEL_CHECK();
    CUDA_CHECK(cudaDeviceSynchronize());
}

GLOBAL void InitializeRandomnessKernel(const size_t size, curandState* randomStates, const unsigned long long seed) {
    const auto idx = threadIdx.x + blockIdx.x * blockDim.x;
    if (idx >= size) return;
    curand_init(seed, idx, 0, &randomStates[idx]);
}

void BatchExecutor::FindChildren(const BatchSoACheckersStateHost& h_batch, const BatchLegalActionsHost& h_actions) {
    constexpr auto size = 1;
    BatchSoACheckersStateResource r_batch(h_batch, size);
    BatchLegalActionsResource r_actions(size);
    constexpr auto gridSize = size;
    constexpr auto blockSize = 32;
    constexpr auto shmSize = size * SharedMemorySize;
    FindChildrenKernel<<<gridSize, blockSize, shmSize>>>(size, r_batch.self_.get(), r_actions.self_.get());
    KERNEL_CHECK();
    h_actions.CopyFromGpu(r_actions);
}

GLOBAL void FindChildrenKernel(const size_t batchSize, const BatchSoACheckersStateDevice *d_states, BatchLegalActionsDevice *d_actions) {
    extern __shared__ char shm[];
    GetLegalActions(shm, batchSize, d_states, d_actions);
}


void BatchExecutor::Expand(MctsTocpuwbNode *node, const BatchLegalActionsHost &h_children) {
    const auto childrenForNode = h_children.actions_[0];
    node->childrenCount_ = childrenForNode.size_;
    node->children_ = new MctsTocpuwbNode[node->childrenCount_];
    for (auto i = 0; i < node->childrenCount_; i++) {
        auto* const child = &node->children_[i];
        child->parent_ = node;
        child->children_ = nullptr;
        child->childrenCount_ = 0;
        child->state_ = childrenForNode.buffer_[i];
        child->reward_ = 0.0f;
        child->visitCount_ = 0; //has to be set in AssignRewards because 0 would cause div by 0 in selection
    }
}

void BatchExecutor::Simulate(const size_t batchSize, curandState* randomStates, const BatchSoACheckersStateHost &h_batch, BatchSimulationResultsHost &h_results) {
    BatchSoACheckersStateResource r_batch(h_batch, batchSize);
    BatchLegalActionsResource r_actions(batchSize);
    BatchSimulationResultsResource r_results(batchSize);
    constexpr auto threadsPerState = 32;
    const auto stateCount = batchSize;
    const auto totalStates = threadsPerState * stateCount;
    //we can only fit about 6 states in a block at once, due to big shm size(totalShm / SharedMemorySize)
    constexpr auto statesPerBlock = 6;
    const auto blockSize = statesPerBlock * threadsPerState;
    const auto gridSize = (totalStates + blockSize - 1) / blockSize;
    const auto shmSize = statesPerBlock * SharedMemorySize;
    SimulateKernel<<<gridSize, blockSize, shmSize>>>(batchSize, randomStates, r_batch.self_.get(), r_actions.self_.get(), r_results.self_.get());
    KERNEL_CHECK();
    h_results.CopyFromGpu(r_results);
}

GLOBAL void SimulateKernel(const size_t batchSize, curandState* randomStates, const BatchSoACheckersStateDevice *states, BatchLegalActionsDevice *actions, BatchSimulationResultsDevice* results) {
    extern __shared__ char shm[];
    const auto idx = threadIdx.x + blockIdx.x * blockDim.x;
    const auto boardId = idx / FIELD_COUNT;
    auto gameEnd = false;
    auto randomState = &randomStates[idx];
    while (true) {
        CheckTerminal(batchSize, states, results, &gameEnd);
        if (gameEnd) {
            return; //either entire warp exits, or no thread exit
        }

        GetLegalActions(shm, batchSize, states, actions);
        //symbol of loss due to lack of moves
        if (actions->actions_[boardId].size_ == 0) {
            if (idx % 32 == 0) {
                const auto isWhiteToMove = states->metadata_[boardId] & 256;
                results->results_[boardId] = isWhiteToMove ? -1.0f : 1.0f;
            }
            return;
        }
        if (idx % 32 == 0) {
            const auto randomNewStateIndex = curand(randomState) % actions->actions_[boardId].size_;
            const auto newState = actions->actions_[boardId].buffer_[randomNewStateIndex];
            states->whitePawns_[boardId] = newState.whitePawns_;
            states->whiteQueens_[boardId] = newState.whiteQueens_;
            states->blackPawns_[boardId] = newState.blackPawns_;
            states->blackQueens_[boardId] = newState.blackQueens_;
            states->metadata_[boardId] = newState.metadata_;
        }
        __syncthreads();
    }
}

void BatchExecutor::AssignRewards(const MctsTocpuwbNode *node, const BatchSimulationResultsHost &h_results) {
    for (auto i = 0; i < node->childrenCount_; i++) {
        auto* const child = &node->children_[i];
        auto sum = 0.0f;
        for (auto j = 0; j < leafParallelismFactor_; j++) {
            sum += h_results.results_[i * leafParallelismFactor_ + j];
        }
        child->reward_ = sum / leafParallelismFactor_;
        child->visitCount_ = leafParallelismFactor_;
    }
}

