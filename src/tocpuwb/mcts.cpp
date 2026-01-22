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
    if (!ExpansionAndSimulation(node)) return;
    Backpropagation(node);
}

//todo
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
    auto highestUcb = std::numeric_limits<float>::lowest();
    for (int i = 0; i < node->childrenCount_; i++) {
        const auto child = &node->children_[i];

        auto ucbExploitation = child->reward_ / child->visitCount_;
        ucbExploitation = (ucbExploitation + 1.0f) / 2.0f; //normalizing because we operate on [-1, 1] rewards
        //const auto ucbExploration = c_ * sqrtf(log2f(node->visitCount_) / child->visitCount_);

        if (ucbExploitation > highestUcb) {
            highestUcb = ucbExploitation;
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
        auto highestUcb = std::numeric_limits<float>::lowest();
        //temp for testing
        auto avgExploitation = 0.0f;
        auto avgExploration = 0.0f;
        for (int i = 0; i < node->childrenCount_; i++) {
            const auto child = &node->children_[i];

            auto ucbExploitation = child->reward_ / child->visitCount_;
            ucbExploitation = (ucbExploitation + 1.0f) / 2.0f; //normalizing because we operate on [-1, 1] rewards
            const auto ucbExploration = c_ * sqrtf(logf(node->visitCount_) / child->visitCount_);

            //testing
            avgExploration += ucbExploration;
            avgExploitation += ucbExploitation;

            if (const auto ucbScore = ucbExploration + ucbExploitation; ucbScore > highestUcb) {
                highestUcb = ucbScore;
                childWithHighestUcb = child;
            }
        }
        //testing
        avgExploitation /= node->childrenCount_;
        avgExploration /= node->childrenCount_;

        node = childWithHighestUcb;

        //testing
        printf("[selection] chose state with ecb=%f, averages exploration=%f, exploitation=%f:"
               "(( 0x%X || 0x%X || 0x%X || 0x%X || 0x%X ))\n",
            highestUcb,
            avgExploration,
            avgExploitation,
            node->state_.whitePawns_,
            node->state_.whiteQueens_,
            node->state_.blackPawns_,
            node->state_.blackQueens_,
            node->state_.metadata_);
    }
}

bool MctsTocpuwb::ExpansionAndSimulation(MctsTocpuwbNode *node) {
    const auto seed = time(nullptr);
    return batchExecutor_.ParallelFindChildrenAndSimulate(node, seed);
}

void MctsTocpuwb::Backpropagation(MctsTocpuwbNode* node) {
    auto rewardSum = 0.0f;
    auto rewardCount = 0;
    for (int i = 0; i < node->childrenCount_; ++i) {
        rewardSum += node->children_[i].reward_;
        rewardCount += node->children_[i].visitCount_;
    }
    printf("[backpropagation] original reward is: %f for count %d\n", rewardSum, rewardCount);
    auto parent = node;
    while (parent != nullptr) {
        rewardSum *= -1; // we have to switch the meaning of the reward for the opponent's turn
        parent->reward_ += rewardSum;
        parent->visitCount_ += rewardCount;
        parent = parent->parent_;
        printf("[backpropagation] reward is: %f for count %d\n", rewardSum, rewardCount);
    }
    printf("\n\n");
}
