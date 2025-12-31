//
// Created by patryk on 12/30/25.
//

#ifndef MCTS_CHECKERS_HELPERFUNCTIONS_CUH
#define MCTS_CHECKERS_HELPERFUNCTIONS_CUH

#include <checkers/state.hpp>

using Mask = unsigned int;

__device__ bool CheckQueenTakeMoveForMask(
    const Mask &originMask,
    const Mask &takenMask,
    const Mask &destinationMask,
    BoardMap &pawns,
    BoardMap &queens,
    BoardMap &opponentPawns,
    BoardMap &opponentQueens);

__device__ bool CheckPawnTakeMoveForMask(
    const Mask &originMask,
    const Mask &takenMask,
    const Mask &destinationMask,
    BoardMap &pawns,
    BoardMap &queens,
    BoardMap &opponentPawns,
    BoardMap &opponentQueens);

__device__ bool CheckQueenNormalMoveForMask(
    const Mask &originMask,
    const Mask& destinationMask,
    BoardMap &pawns,
    BoardMap &queens,
    BoardMap& opponentPawns,
    BoardMap& opponentQueens);

__device__ bool CheckPawnNormalMoveForMask(
    const Mask &originMask,
    const Mask& destinationMask,
    BoardMap &pawns,
    BoardMap &queens,
    BoardMap& opponentPawns,
    BoardMap& opponentQueens);

__device__ void CompleteQueenTakeMove(CheckersState &state);
__device__ void CompletePawnTakeMove(CheckersState &state);
__device__ void CompleteQueenNormalMove(CheckersState &state);
__device__ void CompletePawnNormalMove(CheckersState &state);

template<Players player>
__device__ void AssignSides(
    const CheckersState &state,
    BoardMap &pawns,
    BoardMap &queens,
    BoardMap &opponentPawns,
    BoardMap &opponentQueens);


#endif //MCTS_CHECKERS_HELPERFUNCTIONS_CUH