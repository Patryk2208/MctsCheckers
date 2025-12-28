//
// Created by patryk on 12/27/25.
//

#ifndef MCTS_CHECKERS_BATCHQUEUE_HPP
#define MCTS_CHECKERS_BATCHQUEUE_HPP

#include <vector>
#include <map>
#include "tocpuwb/batchExecutor.cuh"

struct MctsTocpuwbNode;

class BatchQueue {
    int batchSize_;
    BatchExecutor executor_;
public:
    BatchQueue(int batchSize);
    ~BatchQueue();

    std::map<MctsTocpuwbNode*, std::vector<CheckersState>> nodes_;
    std::vector<std::pair<MctsTocpuwbNode*, float>> results_;

    bool PushActions(MctsTocpuwbNode* node, const std::vector<CheckersState>& actions);
    void RunSimulations();
};

#endif //MCTS_CHECKERS_BATCHQUEUE_HPP