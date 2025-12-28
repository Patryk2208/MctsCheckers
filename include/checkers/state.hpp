//
// Created by patryk on 12/27/25.
//

#ifndef MCTS_CHECKERS_STATE_HPP
#define MCTS_CHECKERS_STATE_HPP

#include <cstdint>
#include <vector>

enum Players {
    PlayerA,
    PlayerB
};

using BoardMap = uint32_t;
using BoardMapMetadata = uint32_t;

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

#endif //MCTS_CHECKERS_STATE_HPP