//
// Created by patryk on 12/27/25.

#ifndef MCTS_CHECKERS_BATCHEXECUTOR_CUH
#define MCTS_CHECKERS_BATCHEXECUTOR_CUH
#include <checkers/state.hpp>
#include <checkers/actions/actions.cuh>
#include <cudaUtils/smartPointer.cuh>


/**
 * Lives both on host and device, for batch copying
 */
struct BatchSoACheckersState {
    BoardMap* whiteQueens_;
    BoardMap* whitePawns_;
    BoardMap* blackQueens_;
    BoardMap* blackPawns_;
    BoardMapMetadata* metadata_;

    BatchSoACheckersState(std::vector<CheckersState>& states);
    ~BatchSoACheckersState();
    CudaResource<BatchSoACheckersState> &CopyToGpu(size_t size) const;
};

struct BatchLegalActions {
    ResultLegalActionSpace* actions_;

    void CopyFromGpu(CudaResource<BatchLegalActions>& resource);
};

struct BatchResults {
    float* results_;

public:
    void CopyFromGpu(CudaResource<float>& d_results);
};


class BatchExecutor {
public:
    void Test(size_t size, BatchSoACheckersState batch, BatchLegalActions actions);
    void Run(size_t size, BatchSoACheckersState batch, BatchResults results);
};

#endif //MCTS_CHECKERS_BATCHEXECUTOR_CUH