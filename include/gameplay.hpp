//
// Created by patryk on 1/23/26.
//

#ifndef MCTS_CHECKERS_GAMEPLAY_HPP
#define MCTS_CHECKERS_GAMEPLAY_HPP

//
// Created by patryk on 1/23/26.
//
#include <iostream>
#include <string>
#include <vector>

#include "checkers/state.hpp"

// Use 64-bit board representation
using Bitboard = uint64_t;

struct CheckersState64 {
    Bitboard whitePawns;
    Bitboard whiteQueens;
    Bitboard blackPawns;
    Bitboard blackQueens;
    bool whiteTurn;  // true = white's turn
};


// Helper functions based on your specifications
bool isWhiteTurn(const CheckersState& s);

// Convert row,col (0-7,0-7) to bit position (0-31, MSB=top-right black square)
int boardPosToBit(int row, int col);

// Convert algebraic (e.g., "d2") to bit position
int algebraicToBit(const std::string& alg);

// Convert bit position to algebraic
std::string bitToAlgebraic(int bit);

// Get piece character at a bit position
char getPieceAt(const CheckersState& state, int bit);

// Display the board state
void displayState(const CheckersState& state);

// Parse move string (e.g., "d2-e3", "d2:f4", "d2:f4:d6")
std::vector<int> parseMove(const std::string& moveStr);

// Get move input from user
std::vector<int> getMoveInput();


// Convert 32-bit representation to 64-bit
CheckersState64 convertTo64(const CheckersState& state32);

// Convert 64-bit back to 32-bit
CheckersState convertTo32(const CheckersState64& state64);

CheckersState applyMove(const CheckersState& state, const std::vector<int>& squares);

// Convert between representations
int bit32To64(int bit32);

int square64ToBit32(int square64);

// Get piece at 64-bit square
char getPieceAt64(const CheckersState64& state, int square64);

// Check if square is dark (playable)
bool isDarkSquare(int square64);

// Get direction between squares
int getDirection(int from, int to);

// Check if path is clear for queen
bool isPathClear(const CheckersState64& state, int from, int to, int direction);

#endif //MCTS_CHECKERS_GAMEPLAY_HPP