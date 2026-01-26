//
// Created by patryk on 12/19/25.
//

#include <chrono>

#include "tocpuwb/mcts.hpp"
#include <cmath>
#include <CLI/CLI.hpp>

#include "../include/gameplay.hpp"
#include "tocpuwb/serialization.hpp"

int main(int argc, char** argv) {
    //FIXED bug1: 0x200C3 || 0x40000000 || 0x10480000 || 0x0 || 0x0, queen jumps over its pawn
    //bug2: differentiate between final position in selection and won position

    CLI::App app{"Mcts for Checkers"};

    auto human_cmd = app.add_subcommand("human", "Human vs Algorithm mode");
    auto alg_cmd = app.add_subcommand("mcts", "Algorithm vs Algorithm mode");
    auto learn_cmd = app.add_subcommand("learn", "Learn");

    //common variables
    float c = sqrtf(2);
    int leafParallelizationFactor = 32;

    // Variables for human mode
    std::string human_db_path;
    int human_alg_time = 5;

    // Variables for alg mode
    std::string alg1_db, alg2_db;
    int alg1_time = 5, alg2_time = 5;
    bool noDisplay = false;

    //Variables for learn mode
    std::string learn_alg_db;
    int iterations;

    app.add_option("-c", c, "c param for mcts");
    app.add_option("--lpf", leafParallelizationFactor, "Leaf parallelization factor for mcts");

    // Configure human subcommand
    human_cmd->add_option("-d", human_db_path, "Path to algorithm database, RELATIVE to project root");

    human_cmd->add_option("-t", human_alg_time,
                         "Algorithm response time in seconds (default: 5.0)")
        ->capture_default_str()
        ->check(CLI::Range(1, 5));

    // Configure alg subcommand
    alg_cmd->add_option("--d1", alg1_db, "Path to first algorithm database, RELATIVE to project root");

    alg_cmd->add_option("--d2", alg2_db, "Path to second algorithm database, RELATIVE to project root");

    alg_cmd->add_flag("--nd", noDisplay, "if set, the game will not be displayed, just the results");

    alg_cmd->add_option("--t1", alg1_time,
                       "First algorithm response time in seconds (default: 5.0)")
        ->capture_default_str()
        ->check(CLI::Range(0, 10));

    alg_cmd->add_option("--t2", alg2_time,
                       "Second algorithm response time in seconds (default: 5.0)")
        ->capture_default_str()
        ->check(CLI::Range(0, 10));

    // Configure learn subcommand
    learn_cmd->add_option("-d", learn_alg_db, "Path to algorithm database, RELATIVE to project root");

    learn_cmd->add_option("--iterations", iterations,
                         "Algorithm response time in seconds (default: 5.0)")
        ->capture_default_str()
        ->check(CLI::Range(1, 1000000000));

    try {
        app.parse(argc, argv);
    } catch (const CLI::ParseError &e) {
        return app.exit(e);
    }

    if (*human_cmd) {
        MctsStorage* storage;
        try {
            storage = new MctsStorage(std::string(PROJECT_ROOT) + human_db_path);
        } catch (...) {
            storage = nullptr;
        }
        auto mcts = new MctsTocpuwb(c, leafParallelizationFactor, human_alg_time, storage);

        auto game = GameSequence();
        constexpr auto start = StartState;
        game.history_.push_back(start);

        while (true) {
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
                } catch (...) {
                    displayState(game.history_.back());
                    std::cout << "\n************\n" << "BAD MOVE" << std::endl;
                    continue;
                }
                try {
                    const auto res = mcts->FindBestMove(&game);
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

        delete mcts;
        delete storage;
    }
    else if (*alg_cmd) {
        MctsStorage* storage1;
        MctsStorage* storage2;
        try {
            storage1 = new MctsStorage(std::string(PROJECT_ROOT) + alg1_db);
        } catch (...) {
            storage1 = nullptr;
        }
        try {
            storage2 = new MctsStorage(std::string(PROJECT_ROOT) + alg2_db);
        } catch (...) {
            storage2 = nullptr;
        }
        auto mcts1 = new MctsTocpuwb(c, leafParallelizationFactor, alg1_time, storage1);
        auto mcts2 = new MctsTocpuwb(c, leafParallelizationFactor, alg2_time, storage2);

        auto currentlyMoving = mcts1;
        auto currentlyWaiting = mcts2;

        auto game = GameSequence();
        constexpr auto start = StartState;
        game.history_.push_back(start);

        while (true) {
            const auto currentState = game.history_.back();
            if (!noDisplay) {
                displayState(currentState);

                if (isWhiteTurn(currentState)) {
                    std::cout << "\nWhite's turn (●)\n";
                } else {
                    std::cout << "\nBlack's turn (○)\n";
                }
            }

            const auto res = currentlyMoving->FindBestMove(&game);
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
                break;
            }
            std::swap(currentlyWaiting, currentlyMoving);
        }

        delete mcts1; delete mcts2;
        delete storage1; delete storage2;
    }
    else if (*learn_cmd) {
        MctsStorage* storage;
        try {
            storage = new MctsStorage(std::string(PROJECT_ROOT) + learn_alg_db);
        } catch (...) {
            storage = nullptr;
        }
        auto mcts = new MctsTocpuwb(c, leafParallelizationFactor, 0, storage);
        auto start = std::chrono::high_resolution_clock::now();
        for (auto i = 0; i < iterations; i++) {
            mcts->Learn();
            if (i % 10000 == 0 && i > 0)
                fprintf(stderr, "\n");
            if (i % 100 == 0)
                fprintf(stderr, ".");
        }
        printf("\n");
        auto stop = std::chrono::high_resolution_clock::now();
        auto elapsed = std::chrono::duration_cast<std::chrono::milliseconds>(stop - start);
        printf("Elapsed time: %ld", elapsed.count());

        delete mcts;
        delete storage;
    }
}
