//
// Created by patryk on 12/27/25.
//

#ifndef MCTS_CHECKERS_MCTS_HPP
#define MCTS_CHECKERS_MCTS_HPP

#include "batchExecutor.cuh"
#include "serialization.hpp"
#include "tocpuwb/tree.hpp"

#define PRECOMPUTED_ITERATIONS_PER_SECOND 500

class MctsTocpuwb {
    MctsTocpuwbNode *root_;
    float c_;
    BatchExecutor batchExecutor_;
    MctsStorage* storage_;
public:
    MctsTocpuwb(float c, int leafParallelizationFactor, MctsStorage *storage = nullptr);
    ~MctsTocpuwb();

    bool Learn(MctsTocpuwbNode *node = nullptr);
    bool FindBestMove(GameSequence* game, int timeLimitSeconds);
private:
    MctsTocpuwbNode* Selection(MctsTocpuwbNode* node) const;
    bool ExpansionAndSimulation(MctsTocpuwbNode *node);
    void Backpropagation(MctsTocpuwbNode* node);
};

#endif //MCTS_CHECKERS_MCTS_HPP