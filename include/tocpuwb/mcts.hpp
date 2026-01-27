//
// Created by patryk on 12/27/25.
//

#ifndef MCTS_CHECKERS_MCTS_HPP
#define MCTS_CHECKERS_MCTS_HPP

#include "batchExecutor.cuh"
#include "serialization.hpp"
#include "tocpuwb/tree.hpp"

struct GameResult {
    bool gameOver_;
    int result_;
};

class MctsTocpuwb {
    MctsTocpuwbNode *root_;
    float c_;
    BatchExecutor batchExecutor_;
    MctsStorage* storage_;
    int timeLimitSeconds_;
    int iterationsPerMove_;

    std::unordered_map<GameSequence*, MctsTocpuwbNode*> lastGameAccessCache_;
public:
    MctsTocpuwb(float c, int lpf, int spb, int ipm, int tpm, MctsStorage *storage = nullptr);
    ~MctsTocpuwb();

    void Learn(MctsTocpuwbNode *node = nullptr);

    GameResult FindBestMove(GameSequence *game);
private:
    MctsTocpuwbNode* Selection(MctsTocpuwbNode* node) const;

    void ExpansionAndSimulation(MctsTocpuwbNode *node);
    void Backpropagation(MctsTocpuwbNode* node);
};

#endif //MCTS_CHECKERS_MCTS_HPP