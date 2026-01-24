//
// Created by patryk on 12/19/25.
//

#include <chrono>

#include "tocpuwb/batchExecutor.cuh"
#include "tocpuwb/mcts.hpp"
#include <cmath>

#include "gameplay.hpp"
#include "tocpuwb/serialization.hpp"

int main() {
    //FIXED bug1: 0x200C3 || 0x40000000 || 0x10480000 || 0x0 || 0x0, queen jumps over its pawn
    //bug2: differentiate between final position in selection and won position

    auto storage = MctsStorage(std::string(PROJECT_ROOT) + "/db/correct_leaf_32.db");
    auto mcts = MctsTocpuwb(sqrtf(2), 32, &storage);

    auto game = GameSequence();
    game.history_.push_back(CheckersState
        {
            0b00000000000000000000111111111111,
            0b11111111111100000000000000000000,
            0,
            0,
            0
        });
    constexpr auto timeLimitPerMove = 5;

    while (true) {
        // Clear screen (optional)
        // std::cout << "\033[2J\033[H";

        const auto currentState = game.history_.back();
        displayState(currentState);

        if (isWhiteTurn(currentState)) {
            std::cout << "\nWhite's turn (●)\n";
        } else {
            std::cout << "\nBlack's turn (○)\n";
        }

        auto end = false;
        while (true) {
            try {
                auto moveSquares = getMoveInput();
                if (moveSquares.empty()) {
                    std::cout << "Exiting...\n";
                    break;
                }

                auto newState = applyMove(currentState, moveSquares);
                game.history_.push_back(newState);
                displayState(newState);

                const auto res = mcts.FindBestMove(&game, timeLimitPerMove);
                if (res.gameOver_) {
                    std::cout << "\nGAME END\n";
                    if (res.result_ == 1) {
                        std::cout << "\nWhite Won (●)\n";
                    } else if (res.result_ == -1) {
                        std::cout << "\nBlack Won (○)\n";
                    }
                    else {
                        std::cout << "\nDraw\n";
                    }
                    end = true;
                }
                break;
            }
            catch (...) {
                game.history_.pop_back();
                displayState(game.history_.back());
                std::cout << "\n************\n" << "BAD MOVE" << std::endl;
            }
        }
        if (end) break;
    }


    /*auto start = std::chrono::high_resolution_clock::now();
    auto mctsIterations = 10000;
    for (auto i = 0; i < mctsIterations; i++) {
        mcts.Learn();
        if (i % 10000 == 0 && i > 0)
            fprintf(stderr, "\n");
        if (i % 100 == 0)
            fprintf(stderr, ".");
    }
    printf("\n");
    auto stop = std::chrono::high_resolution_clock::now();
    auto elapsed = std::chrono::duration_cast<std::chrono::milliseconds>(stop - start);
    printf("Elapsed time: %ld", elapsed.count());*/
}
