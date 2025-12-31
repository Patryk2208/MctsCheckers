//
// Created by patryk on 12/27/25.
//

#ifndef MCTS_CHECKERS_STATE_HPP
#define MCTS_CHECKERS_STATE_HPP

#include <vector>
#include <cudaUtils/cudaCompatibility.hpp>
#include "cudaUtils/smartPointer.cuh"

#define FIELD_COUNT 32

struct ResultLegalActionSpace;

enum Players : unsigned {
    WhitePlayer,
    BlackPlayer
};

using BoardMap = unsigned;
using BoardMapMetadata = unsigned;

struct CheckersState {
    BoardMap whitePawns_;
    BoardMap blackPawns_;
    BoardMap whiteQueens_;
    BoardMap blackQueens_;
    BoardMapMetadata metadata_;

public:
    std::vector<CheckersState> GetLegalActions();
    float CheckIfTerminal();
    Players GetPlayer();
};

/**
 * Lives both on host and device, for batch copying
 */
struct BatchSoACheckersState {
    BoardMap* whiteQueens_;
    BoardMap* whitePawns_;
    BoardMap* blackQueens_;
    BoardMap* blackPawns_;
    BoardMapMetadata* metadata_;

    H BatchSoACheckersState(std::vector<CheckersState>& states);
    H ~BatchSoACheckersState();
    H CudaResource<BatchSoACheckersState> &CopyToGpu(size_t size) const;
};

struct BatchLegalActions {
    ResultLegalActionSpace* actions_;

    H void CopyFromGpu(CudaResource<BatchLegalActions>& resource);
};

struct BatchResults {
    float* results_;

public:
    H void CopyFromGpu(CudaResource<float>& d_results);
};

#endif //MCTS_CHECKERS_STATE_HPP