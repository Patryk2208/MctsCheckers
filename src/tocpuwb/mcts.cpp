//
// Created by patryk on 12/27/25.
//

#include "tocpuwb/mcts.hpp"
#include <limits>
#include <cmath>

MctsTocpuwb::MctsTocpuwb(const float c, const int leafParallelizationFactor, const int timePerMove, MctsStorage *storage)
    : c_(c), batchExecutor_(leafParallelizationFactor), storage_(storage), timeLimitSeconds_(timePerMove) {
    if (leafParallelizationFactor == 32) {
        precomputedIterations_ = PRECOMPUTED_ITERATIONS_PER_SECOND_FOR_LEAF_32;
    } else {
        precomputedIterations_ = PRECOMPUTED_ITERATIONS_PER_SECOND_FOR_LEAF_8;
    }
    root_ = nullptr;
    if (storage != nullptr) {
        try {
            root_ = storage_->LoadTree();
        }
        catch (...) {}
    }
    if (!root_) {
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
            0
        };
    }
}

MctsTocpuwb::~MctsTocpuwb() {
    if (storage_ != nullptr)
        storage_->SaveTree(root_);
}

void MctsTocpuwb::Learn(MctsTocpuwbNode *root) {
    if (root == nullptr)
        root = root_;
    const auto node = Selection(root);
    if (node == nullptr) throw std::logic_error("Should always get to a leaf");
    ExpansionAndSimulation(node);
    Backpropagation(node);
}

GameResult MctsTocpuwb::FindBestMove(GameSequence *game) {
    auto node = root_;

    auto didLearn = false;

    for (auto j = 0; j < game->history_.size() - 1; ++j) {

        if (node->childrenCount_ == 0 || timeLimitSeconds_ > 0) {
            const auto tl = timeLimitSeconds_ == 0 ? 4 : timeLimitSeconds_;
            for (auto iter = 0; iter < (tl * precomputedIterations_ / 2); ++iter) {
                Learn(node);
            }
            didLearn = true;
        }

        if (node->childrenCount_ == 0) {
            //children are not created only if they do not exist, only then does the game end
            //although here it will not happen, but a precaution
            int res;
            if ((node->state_.metadata_ & 15) == 15) res = 0;
            else if (node->state_.metadata_ & 128) res = -1;
            else res = 1;
            return GameResult{true, res};
        }

        const auto nextState = game->history_[j + 1];
        auto foundNextState = false;
        for (int i = 0; i < node->childrenCount_; i++) {
            const auto child = &node->children_[i];
            if (child->state_ == nextState) {
                node = child;
                foundNextState = true;
                break;
            }
        }
        if (!foundNextState) {
            throw std::logic_error("Not a valid state");
        }
    }

    if (node->childrenCount_ == 0 || timeLimitSeconds_ > 0) {
        const auto tl = timeLimitSeconds_ == 0 ? 4 : timeLimitSeconds_;
        auto maxIterations = didLearn ? (tl * precomputedIterations_ / 2) : tl * precomputedIterations_;
        for (auto iter = 0; iter < maxIterations; ++iter) {
            Learn(node);
        }
    }
    if (node->childrenCount_ == 0) {
        //children are not created only if they do not exist, only then does the game end
        int res;
        if ((node->state_.metadata_ & 15) == 15) res = 0;
        else if (node->state_.metadata_ & 128) res = -1;
        else res = 1;
        return GameResult{true, res};
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
    return GameResult{false, 0};
}

MctsTocpuwbNode *MctsTocpuwb::Selection(MctsTocpuwbNode* node) const {
    constexpr int hardMaxIter = 500; //should never stop anything, but prevents infinite loops
    auto i = 0;
    while (i++ < hardMaxIter) {
        if (node->childrenCount_ == 0) {
            return node;
        }
        MctsTocpuwbNode* childWithHighestUcb = nullptr;
        auto highestUcb = std::numeric_limits<float>::lowest();
        for (int i = 0; i < node->childrenCount_; i++) {
            const auto child = &node->children_[i];

            auto ucbExploitation = child->reward_ / child->visitCount_;
            ucbExploitation = (ucbExploitation + 1.0f) / 2.0f; //normalizing because we operate on [-1, 1] rewards
            const auto ucbExploration = c_ * sqrtf(logf(node->visitCount_) / child->visitCount_);

            if (const auto ucbScore = ucbExploration + ucbExploitation; ucbScore > highestUcb) {
                highestUcb = ucbScore;
                childWithHighestUcb = child;
            }
        }
        node = childWithHighestUcb;

        //testing
        /*printf("[selection] chose state with ecb=%f, averages exploration=%f, exploitation=%f:"
               "(( 0x%X || 0x%X || 0x%X || 0x%X || 0x%X ))\n",
            highestUcb,
            avgExploration,
            avgExploitation,
            node->state_.whitePawns_,
            node->state_.whiteQueens_,
            node->state_.blackPawns_,
            node->state_.blackQueens_,
            node->state_.metadata_);*/
    }
    return nullptr;
}

void MctsTocpuwb::ExpansionAndSimulation(MctsTocpuwbNode *node) {
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
    //printf("[backpropagation] original reward is: %f for count %d\n", rewardSum, rewardCount);
    auto parent = node;
    while (parent != nullptr) {
        rewardSum *= -1; // we have to switch the meaning of the reward for the opponent's turn
        parent->reward_ += rewardSum;
        parent->visitCount_ += rewardCount;
        parent = parent->parent_;
        //printf("[backpropagation] reward is: %f for count %d\n", rewardSum, rewardCount);
    }
    //printf("\n\n");
}
