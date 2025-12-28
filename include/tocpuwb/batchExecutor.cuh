//
// Created by patryk on 12/27/25.

#ifndef MCTS_CHECKERS_BATCHEXECUTOR_CUH
#define MCTS_CHECKERS_BATCHEXECUTOR_CUH
#include <checkers/state.hpp>


/**
 * Lives both on host and device, for batch copying
 */
struct BatchSoACheckersState {
    BoardMap* whitePawns_;
    BoardMap* blackPawns_;
    BoardMap* whiteQueens_;
    BoardMap* blackQueens_;
    BoardMapMetadata* metadata_;
};

struct BatchResults {
    float* results_;
};


class BatchExecutor {
public:
    void Run(BatchSoACheckersState batch, BatchResults results);
private:
    void CopyBatch();
    void RunBatch();
    void CopyResults();
};

#endif //MCTS_CHECKERS_BATCHEXECUTOR_CUH