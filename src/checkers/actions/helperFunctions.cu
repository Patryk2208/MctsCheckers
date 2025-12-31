//
// Created by patryk on 12/31/25.
//

#include <checkers/actions/helperFunctions.cuh>

__device__ bool CheckQueenTakeMoveForMask(
    const Mask &originMask,
    const Mask &takenMask,
    const Mask &destinationMask,
    BoardMap &pawns,
    BoardMap &queens,
    BoardMap &opponentPawns,
    BoardMap &opponentQueens) {
    //todo
}

__device__ bool CheckPawnTakeMoveForMask(
    const Mask &originMask,
    const Mask &takenMask,
    const Mask& destinationMask,
    BoardMap &pawns,
    BoardMap &queens,
    BoardMap& opponentPawns,
    BoardMap& opponentQueens) {
    auto isOpponentTaken = ((opponentPawns & takenMask) || (opponentQueens & takenMask));
    auto isDestinationFree = !(opponentPawns & destinationMask || opponentQueens & destinationMask || pawns & destinationMask || queens & destinationMask);
    if (isOpponentTaken && isDestinationFree) {
        pawns &= !originMask;
        pawns |= destinationMask;
        if (opponentPawns & takenMask) {
            opponentPawns &= !takenMask;
        }
        else {
            opponentQueens &= !takenMask;
        }
        return true;
    }
    return false;
}

__device__ bool CheckQueenNormalMoveForMask(
    const Mask &originMask,
    const Mask& destinationMask,
    BoardMap &pawns,
    BoardMap &queens,
    BoardMap& opponentPawns,
    BoardMap& opponentQueens) {
    //todo
}

__device__ bool CheckPawnNormalMoveForMask(
    const Mask &originMask,
    const Mask& destinationMask,
    BoardMap &pawns,
    BoardMap &queens,
    BoardMap& opponentPawns,
    BoardMap& opponentQueens) {
    auto isDestinationFree = !(pawns & destinationMask || opponentPawns & destinationMask || queens & destinationMask || opponentQueens & destinationMask);
    if (isDestinationFree) {
        pawns &= !originMask;
        pawns |= destinationMask;
        return true;
    }
    return false;
}


__device__ void CompleteQueenTakeMove(CheckersState &state) {
    //todo
}

__device__ void CompletePawnTakeMove(CheckersState &state) {
    state.metadata_ ^= 0b10000000; //changing the turn
    state.metadata_ &= 0b11110000; //resetting the draw count
    //todo promotion
}

__device__ void CompleteQueenNormalMove(CheckersState &state) {
    //todo
}

__device__ void CompletePawnNormalMove(CheckersState &state) {
    state.metadata_ ^= 0b10000000; //changing the turn
    state.metadata_ &= 0b11110000; //resetting the draw count
    //todo promotion
}


template<Players player>
__device__ void AssignSides(
    const CheckersState &state,
    BoardMap &pawns,
    BoardMap &queens,
    BoardMap &opponentPawns,
    BoardMap &opponentQueens) {
    if constexpr (player == WhitePlayer) {
        pawns = state.whitePawns_;
        queens = state.whiteQueens_;
        opponentPawns = state.blackPawns_;
        opponentQueens = state.blackQueens_;
    }
    else {
        pawns = state.blackPawns_;
        queens = state.blackPawns_;
        opponentPawns = state.whitePawns_;
        opponentQueens = state.whiteQueens_;
    }
}