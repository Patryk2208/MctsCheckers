//
// Created by patryk on 12/27/25.
//

#ifndef MCTS_CHECKERS_MCTS_HPP
#define MCTS_CHECKERS_MCTS_HPP

#include "batchExecutor.cuh"
#include "tocpuwb/tree.hpp"

class MctsTocpuwb {
    MctsTocpuwbNode *root_;
    float c_;
    BatchExecutor batchExecutor_;
public:
    MctsTocpuwb(float c, int leafParallelizationFactor);
    ~MctsTocpuwb();
    void Learn(MctsTocpuwbNode* node = nullptr);
    bool FindBestMove(GameSequence* game);
private:
    MctsTocpuwbNode* Selection(MctsTocpuwbNode* node) const;
    void ExpansionAndSimulation(MctsTocpuwbNode* node);
    void Backpropagation(MctsTocpuwbNode* node);
};

#endif //MCTS_CHECKERS_MCTS_HPP