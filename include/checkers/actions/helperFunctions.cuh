//
// Created by patryk on 12/30/25.
//

#ifndef MCTS_CHECKERS_HELPERFUNCTIONS_CUH
#define MCTS_CHECKERS_HELPERFUNCTIONS_CUH

#include <checkers/state.hpp>

using Mask = unsigned int;

__device__ Mask GetMask(const unsigned& originalFieldId, const unsigned& currentFieldId);

/**
 * Only if we are sure there is our queen at originMask
 */
__device__ bool CheckQueenTakeMoveForMask(
    const Mask &originMask,
    const Mask &takenMask,
    const Mask &destinationMask,
    BoardMap &pawns,
    BoardMap &queens,
    BoardMap &opponentPawns,
    BoardMap &opponentQueens);

/**
 * Only if we are sure there is our pawn at originMask
 */
__device__ bool CheckPawnTakeMoveForMask(
    const Mask &originMask,
    const Mask &takenMask,
    const Mask &destinationMask,
    BoardMap &pawns,
    BoardMap &queens,
    BoardMap &opponentPawns,
    BoardMap &opponentQueens);

/**
 * Only if we are sure there is our queen at originMask
 */
__device__ bool CheckQueenNormalMoveForMask(
    const Mask &originMask,
    const Mask& destinationMask,
    BoardMap &pawns,
    BoardMap &queens,
    BoardMap& opponentPawns,
    BoardMap& opponentQueens);

/**
 * Only if we are sure there is our pawn at originMask
 */
__device__ bool CheckPawnNormalMoveForMask(
    const Mask &originMask,
    const Mask& destinationMask,
    BoardMap &pawns,
    BoardMap &queens,
    BoardMap& opponentPawns,
    BoardMap& opponentQueens);


template<Players player>
__device__ void CompleteQueenTakeMove(const unsigned &fieldId, CheckersState &state);

template<Players player>
__device__ void CompletePawnTakeMove(const unsigned &fieldId, CheckersState &state);

template<Players player>
__device__ void CompleteQueenNormalMove(const unsigned &fieldId, CheckersState &state);

template<Players player>
__device__ void CompletePawnNormalMove(const unsigned &fieldId, CheckersState &state);

template<Players player>
__device__ void AssignSides(
    const CheckersState &state,
    BoardMap &pawns,
    BoardMap &queens,
    BoardMap &opponentPawns,
    BoardMap &opponentQueens);


#endif //MCTS_CHECKERS_HELPERFUNCTIONS_CUH