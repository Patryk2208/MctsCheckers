//
// Created by patryk on 12/27/25.
//

#ifndef MCTS_CHECKERS_MCTS_HPP
#define MCTS_CHECKERS_MCTS_HPP

#include "tocpuwb/tree.hpp"

class MctsTocpuwbAlgorithm {
    MctsTocpuwbNode *root_;
    float c_;
    BatchQueue batchQueue_;
public:
    MctsTocpuwbAlgorithm();
    ~MctsTocpuwbAlgorithm();
    void Learn();
    void Play();
private:
    bool Selection();
    void Expansion();
    void Simulation();
    void Backpropagation() const;
};

#endif //MCTS_CHECKERS_MCTS_HPP