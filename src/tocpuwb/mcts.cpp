//
// Created by patryk on 12/27/25.
//

#include "tocpuwb/mcts.hpp"
#include <limits>
#include <cmath>

MctsTocpuwb::MctsTocpuwb(const float c, const int leafParallelizationFactor) : c_(c), batchExecutor_(leafParallelizationFactor) {
    root_ = new MctsTocpuwbNode();
    root_->childrenCount_ = 0;
    root_->parent_ = nullptr;
    root_->visitCount_ = 0;
    root_->reward_ = 0.0f;
    root_->children_ = nullptr;
    root_->state_ = CheckersState
    {
        0b00000000000000000000111111111111,
        0b11111111111100000000000000000000,
        0,
        0,
        0 //todo maybe
    };
}

MctsTocpuwb::~MctsTocpuwb() {
    //todo
}

void MctsTocpuwb::Learn(MctsTocpuwbNode* root) {
    if (root == nullptr) root = root_;
    const auto node = Selection(root);
    ExpansionAndSimulation(node);
    Backpropagation(node);
}

bool MctsTocpuwb::FindBestMove(GameSequence *game) {
    auto node = root_;
    for (const auto state : game->history_) {
        if (node == nullptr) return false;
        if (node->state_ != state) return false;
        if (node->childrenCount_ == 0) {
            const auto n = Selection(node);
            ExpansionAndSimulation(n);
            Backpropagation(n);
        }
        auto foundNextState = false;
        for (int i = 0; i < node->childrenCount_; i++) {
            const auto child = &node->children_[i];
            if (child->state_ == state) {
                node = child;
                foundNextState = true;
                break;
            }
        }
        if (!foundNextState) {
            return false;
        }
    }
    const MctsTocpuwbNode* childWithHighestUcb = nullptr;
    auto highestUcb = std::numeric_limits<float>::min();
    for (int i = 0; i < node->childrenCount_; i++) {
        const auto child = &node->children_[i];

        const auto ucbExploitation = child->reward_ / child->visitCount_;
        const auto ucbExploration = c_ * sqrtf(log2f(node->visitCount_) / child->visitCount_);

        if (const auto ucbScore = ucbExploration + ucbExploitation; ucbScore > highestUcb) {
            highestUcb = ucbScore;
            childWithHighestUcb = child;
        }
    }
    game->history_.push_back(childWithHighestUcb->state_);
    return true;
}

MctsTocpuwbNode *MctsTocpuwb::Selection(MctsTocpuwbNode* node) const {
    while (true) {
        if (node->childrenCount_ == 0) {
            return node;
        }
        MctsTocpuwbNode* childWithHighestUcb = nullptr;
        auto highestUcb = std::numeric_limits<float>::min();
        for (int i = 0; i < node->childrenCount_; i++) {
            const auto child = &node->children_[i];

            const auto ucbExploitation = child->reward_ / child->visitCount_;
            const auto ucbExploration = c_ * sqrtf(log2f(node->visitCount_) / child->visitCount_);

            if (const auto ucbScore = ucbExploration + ucbExploitation; ucbScore > highestUcb) {
                highestUcb = ucbScore;
                childWithHighestUcb = child;
            }
        }
        node = childWithHighestUcb;
    }
}

void MctsTocpuwb::ExpansionAndSimulation(MctsTocpuwbNode* node) {
    const auto seed = time(nullptr);
    batchExecutor_.ParallelFindChildrenAndSimulate(node, seed);
}

void MctsTocpuwb::Backpropagation(MctsTocpuwbNode* node) {
    auto rewardSum = 0.0f;
    auto rewardCount = 0;
    for (int i = 0; i < node->childrenCount_; ++i) {
        rewardSum += node->children_[i].reward_;
        rewardCount += node->children_[i].visitCount_;
    }
    auto parent = node->parent_;
    while (parent != nullptr) {
        parent->reward_ += rewardSum;
        parent->visitCount_ += rewardCount;
        //todo confirm maybe flip the sum only
        rewardSum = rewardCount - rewardSum; // we have to switch the meaning of the reward for the opponent's turn represented in the parent
        parent = parent->parent_;
    }
}
