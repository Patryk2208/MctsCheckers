//
// Created by patryk on 12/27/25.
//

#ifndef MCTS_CHECKERS_STATE_HPP
#define MCTS_CHECKERS_STATE_HPP

#include <vector>
#include <cudaUtils/cudaCompatibility.hpp>
#include "cudaUtils/smartPointer.cuh"

#define FIELD_COUNT 32

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

    Players GetPlayer();

    bool operator==(const CheckersState& other) const {
        return whitePawns_   == other.whitePawns_
            && blackPawns_   == other.blackPawns_
            && whiteQueens_  == other.whiteQueens_
            && blackQueens_  == other.blackQueens_
            && metadata_     == other.metadata_;
    }
};

struct GameSequence {
    std::vector<CheckersState> history_;
};

#endif //MCTS_CHECKERS_STATE_HPP