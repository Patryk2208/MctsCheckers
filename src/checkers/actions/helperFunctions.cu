//
// Created by patryk on 12/31/25.
//

#include <checkers/actions/helperFunctions.cuh>


D Mask GetMask(const unsigned& originalFieldId, const unsigned& currentFieldId) {
    return currentFieldId == originalFieldId ? 0u : 1u << currentFieldId;
}

D bool CheckQueenTakeMoveForMask(
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

D bool CheckPawnTakeMoveForMask(
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

D bool CheckQueenNormalMoveForMask(
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

D bool CheckPawnNormalMoveForMask(
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