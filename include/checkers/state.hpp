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

    std::vector<CheckersState> GetLegalActions();
    float CheckIfTerminal();
    Players GetPlayer();
};

#endif //MCTS_CHECKERS_STATE_HPP