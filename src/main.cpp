//
// Created by patryk on 12/19/25.
//

#include <chrono>

#include "tocpuwb/batchExecutor.cuh"
#include "tocpuwb/mcts.hpp"
#include <cmath>

int main() {
    //FIXED bug1: 0x200C3 || 0x40000000 || 0x10480000 || 0x0 || 0x0, queen jumps over its pawn

    auto mcts = MctsTocpuwb(sqrtf(2), 8);
    auto start = std::chrono::high_resolution_clock::now();
    auto mctsIterations = 1000;
    for (auto i = 0; i < mctsIterations; i++) {
        mcts.Learn();
        if (i % 100 == 0)
            fprintf(stderr, ".");
    }
    printf("\n");
    auto stop = std::chrono::high_resolution_clock::now();
    auto elapsed = std::chrono::duration_cast<std::chrono::milliseconds>(stop - start);
    printf("Elapsed time: %ld", elapsed.count());
}
