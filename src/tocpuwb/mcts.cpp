//
// Created by patryk on 12/27/25.
//

#include "tocpuwb/mcts.hpp"
#include <limits>
#include <cmath>

bool MctsTocpuwbAlgorithm::Selection() {
    auto node = root_;
    while (true) {
        if (node->childrenCount_ == 0) {
            const auto actionSpace = node->state_.GetLegalActions();
            auto end = batchQueue_.PushActions(node, actionSpace);
            return end;
        }
        else {
            MctsTocpuwbNode* childWithHighestUcb = nullptr;
            auto highestUcb = std::numeric_limits<float>::min();
            for (int i = 0; i < node->childrenCount_; i++) {
                auto child = node->children_[i];
                const auto ucbExploitation = child.reward_ / child.visitCount_;
                const auto ucbExploration = c_ * sqrtf(log2f(node->visitCount_) / child.visitCount_);
                if (const auto ucbScore = ucbExploration + ucbExploitation; ucbScore > highestUcb) {
                    highestUcb = ucbScore;
                    childWithHighestUcb = &child;
                }
            }
            node = childWithHighestUcb;
        }
    }
}

void MctsTocpuwbAlgorithm::Expansion() {
    for (const auto& element: batchQueue_.nodes_) {
        auto node = element.first;
        auto& childrenStates = element.second;
        node->children_ = new MctsTocpuwbNode[childrenStates.size()];
        for (int i = 0; i < childrenStates.size(); i++) {
            auto child = node->children_[i];
            child.parent_ = node;
            child.state_ = childrenStates[i];
            child.childrenCount_ = 0;
            child.children_ = nullptr;
        }
    }
}

void MctsTocpuwbAlgorithm::Simulation() {

}

void MctsTocpuwbAlgorithm::Backpropagation() const {
    for (const auto& [fst, snd] : batchQueue_.results_) {
        auto node = fst;
        auto result = snd;
        while (true) {
            node->reward_ += result;
            node->visitCount_++;
            result = 1 - result;
            if (node->parent_ == nullptr)
                break;
            node = node->parent_;
        }
    }
}
