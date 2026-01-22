//
// Created by patryk on 12/19/25.
//

#include "tocpuwb/batchExecutor.cuh"
#include "tocpuwb/mcts.hpp"
#include <cmath>

int main() {
    auto mcts = MctsTocpuwb(sqrtf(2), 1);
    mcts.Learn();
}
