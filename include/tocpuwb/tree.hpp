//
// Created by patryk on 12/27/25.
//

#ifndef MCTS_CHECKERS_TREE_HPP
#define MCTS_CHECKERS_TREE_HPP

#include "checkers/state.hpp"

//Definition of tocpuwb: Tree On CPU With Batching, description in Spec.md

struct MctsTocpuwbNode {
    //structural parameters of the tree
    MctsTocpuwbNode *parent_;
    MctsTocpuwbNode *children_;
    int childrenCount_;

    //state of the game in this node
    CheckersState state_;

    //metrics for selection
    int visitCount_;
    float reward_;
};

#endif //MCTS_CHECKERS_TREE_HPP