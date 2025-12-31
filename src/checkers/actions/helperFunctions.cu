//
// Created by patryk on 12/31/25.
//

#include <checkers/actions/helperFunctions.cuh>


__device__ Mask GetMask(const unsigned& originalFieldId, const unsigned& currentFieldId) {
    return currentFieldId == originalFieldId ? 0u : 1u << currentFieldId;
}

__device__ bool CheckQueenTakeMoveForMask(
    const Mask &originMask,
    const Mask &takenMask,
    const Mask &destinationMask,
    BoardMap &pawns,
    BoardMap &queens,
    BoardMap &opponentPawns,
    BoardMap &opponentQueens) {
    const auto isOpponentTaken = ((opponentPawns & takenMask) || (opponentQueens & takenMask));
    const auto isDestinationFree = !(opponentPawns & destinationMask || opponentQueens & destinationMask || pawns & destinationMask || queens & destinationMask);
    if (isOpponentTaken && isDestinationFree) {
        queens &= !originMask;
        queens |= destinationMask;
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

__device__ bool CheckPawnTakeMoveForMask(
    const Mask &originMask,
    const Mask &takenMask,
    const Mask& destinationMask,
    BoardMap &pawns,
    BoardMap &queens,
    BoardMap& opponentPawns,
    BoardMap& opponentQueens) {
    const auto isOpponentTaken = ((opponentPawns & takenMask) || (opponentQueens & takenMask));
    const auto isDestinationFree = !(opponentPawns & destinationMask || opponentQueens & destinationMask || pawns & destinationMask || queens & destinationMask);
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
    const auto isDestinationFree = !(pawns & destinationMask || opponentPawns & destinationMask || queens & destinationMask || opponentQueens & destinationMask);
    if (isDestinationFree) {
        queens &= !originMask;
        queens |= destinationMask;
        return true;
    }
    return false;
}

__device__ bool CheckPawnNormalMoveForMask(
    const Mask &originMask,
    const Mask& destinationMask,
    BoardMap &pawns,
    BoardMap &queens,
    BoardMap& opponentPawns,
    BoardMap& opponentQueens) {
    const auto isDestinationFree = !(pawns & destinationMask || opponentPawns & destinationMask || queens & destinationMask || opponentQueens & destinationMask);
    if (isDestinationFree) {
        pawns &= !originMask;
        pawns |= destinationMask;
        return true;
    }
    return false;
}


template<Players player>
__device__ void CompleteQueenTakeMove(const unsigned &fieldId, CheckersState &state) {
    state.metadata_ ^= 0b10000000; //changing the turn
    state.metadata_ &= 0b11110000; //resetting the draw count
}

template<Players player>
__device__ void CompletePawnTakeMove(const unsigned &fieldId, CheckersState &state) {
    state.metadata_ ^= 0b10000000; //changing the turn
    state.metadata_ &= 0b11110000; //resetting the draw count
    const auto fieldMask = 1 << fieldId;
    if constexpr (player == WhitePlayer) {
        if (fieldId > 27) {
            state.whitePawns_ ^= fieldMask;
            state.whiteQueens_ ^= fieldMask;
        }
    }
    else {
        if (fieldId < 4) {
            state.blackPawns_ ^= fieldMask;
            state.blackQueens_ ^= fieldMask;
        }
    }
}

template<Players player>
__device__ void CompleteQueenNormalMove(const unsigned &fieldId, CheckersState &state) {
    state.metadata_ ^= 0b10000000; //changing the turn
    state.metadata_++; //updating the draw count
}

template<Players player>
__device__ void CompletePawnNormalMove(const unsigned &fieldId, CheckersState &state) {
    state.metadata_ ^= 0b10000000; //changing the turn
    state.metadata_ &= 0b11110000; //resetting the draw count
    const auto fieldMask = 1 << fieldId;
    if constexpr (player == WhitePlayer) {
        if (fieldId > 27) {
            state.whitePawns_ ^= fieldMask;
            state.whiteQueens_ ^= fieldMask;
        }
    }
    else {
        if (fieldId < 4) {
            state.blackPawns_ ^= fieldMask;
            state.blackQueens_ ^= fieldMask;
        }
    }
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