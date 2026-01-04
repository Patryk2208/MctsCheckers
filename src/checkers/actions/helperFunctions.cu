//
// Created by patryk on 12/31/25.
//

#include <iostream>
#include <checkers/actions/helperFunctions.cuh>

#include "checkers/actions/directionFunctions.cuh"


D Mask GetMask(const unsigned& originalFieldId, const unsigned& currentFieldId) {
    return currentFieldId == originalFieldId ? 0u : 1u << currentFieldId;
}

D bool CheckQueenTakeMoveForMask(
    const Mask &originMask,
    const Mask &takenMask,
    const Mask &destinationMask,
    BoardMap *const pawns,
    BoardMap *const queens,
    BoardMap *const opponentPawns,
    BoardMap *const opponentQueens) {
    const auto isOpponentTaken = ((*opponentPawns & takenMask) || (*opponentQueens & takenMask));
    const auto isDestinationFree = !(*opponentPawns & destinationMask || *opponentQueens & destinationMask || *pawns & destinationMask || *queens & destinationMask);
    if (isOpponentTaken && isDestinationFree) {
        *queens &= ~originMask;
        *queens |= destinationMask;
        if (*opponentPawns & takenMask) {
            *opponentPawns &= ~takenMask;
        }
        else {
            *opponentQueens &= ~takenMask;
        }
        return true;
    }
    return false;
}

D bool CheckForQueenContinuation(
    const unsigned &fieldId,
    BoardMap *pawns,
    BoardMap *queens,
    BoardMap *opponentPawns,
    BoardMap *opponentQueens,
    BoardMapMetadata *metadata
    ) {
    if (GetTopLeftDirection::CanTakeInThatDirection(*metadata)) {
        if (CheckDirectionContinuation<GetTopLeftDirection>(fieldId, pawns, queens, opponentPawns, opponentQueens)) {
            return true;
        }
    }
    if (GetTopRightDirection::CanTakeInThatDirection(*metadata)) {
        if (CheckDirectionContinuation<GetTopRightDirection>(fieldId, pawns, queens, opponentPawns, opponentQueens)) {
            return true;
        }
    }
    if (GetBottomLeftDirection::CanTakeInThatDirection(*metadata)) {
        if (CheckDirectionContinuation<GetBottomLeftDirection>(fieldId, pawns, queens, opponentPawns, opponentQueens)) {
            return true;
        }
    }
    if (GetBottomRightDirection::CanTakeInThatDirection(*metadata)) {
        if (CheckDirectionContinuation<GetBottomRightDirection>(fieldId, pawns, queens, opponentPawns, opponentQueens)) {
            return true;
        }
    }
    return false;
}

D bool CheckPawnTakeMoveForMask(
    const Mask &originMask,
    const Mask &takenMask,
    const Mask& destinationMask,
    BoardMap *const pawns,
    BoardMap *const queens,
    BoardMap *const opponentPawns,
    BoardMap *const opponentQueens) {
    const auto isOpponentTaken = ((*opponentPawns & takenMask) || (*opponentQueens & takenMask));
    const auto isDestinationFree = !(*opponentPawns & destinationMask || *opponentQueens & destinationMask || *pawns & destinationMask || *queens & destinationMask);
    if (isOpponentTaken && isDestinationFree) {
        *pawns &= ~originMask;
        *pawns |= destinationMask;
        if (*opponentPawns & takenMask) {
            *opponentPawns &= ~takenMask;
        }
        else {
            *opponentQueens &= ~takenMask;
        }
        return true;
    }
    return false;
}

D bool CheckQueenNormalMoveForMask(
    const Mask &originMask,
    const Mask& destinationMask,
    BoardMap *const pawns,
    BoardMap *const queens,
    BoardMap *const opponentPawns,
    BoardMap *const opponentQueens) {
    const auto isDestinationFree = !(*pawns & destinationMask || *opponentPawns & destinationMask || *queens & destinationMask || *opponentQueens & destinationMask);
    if (isDestinationFree) {
        *queens &= ~originMask;
        *queens |= destinationMask;
        return true;
    }
    return false;
}

D bool CheckPawnNormalMoveForMask(
    const Mask &originMask,
    const Mask& destinationMask,
    BoardMap *const pawns,
    BoardMap *const queens,
    BoardMap *const opponentPawns,
    BoardMap *const opponentQueens) {
    const auto isDestinationFree = !(*pawns & destinationMask || *opponentPawns & destinationMask || *queens & destinationMask || *opponentQueens & destinationMask);
    if (isDestinationFree) {
        *pawns &= ~originMask;
        *pawns |= destinationMask;
        return true;
    }
    return false;
}

D void PrintShmStructureForBoard(const unsigned &fieldId, const LegalMovesSubStateMap *const structure) {
    const auto activeMask = __activemask();
    __syncwarp(activeMask);
    if (fieldId == __ffs(activeMask) - 1) {
        for (auto j = 0; j < 32; ++j) {
            printf("Field: %u write structure: %u //", j, structure->writeStructures_[j].size_);
            for (int i = 0; i < structure->writeStructures_[j].size_; ++i) {
                printf("%u %u %u %u %u ||| ",
                    structure->writeStructures_[j].buffer_[i].whiteQueens_,
                    structure->writeStructures_[j].buffer_[i].whitePawns_,
                    structure->writeStructures_[j].buffer_[i].blackQueens_,
                    structure->writeStructures_[j].buffer_[i].blackPawns_,
                    structure->writeStructures_[j].buffer_[i].metadata_);
            }
            printf("\n");
            printf("Field: %u read structure: %u ::", j, structure->readStructures_[j].size_);
            for (int i = 0; i < structure->readStructures_[j].size_; ++i) {
                printf("%u %u %u %u %u ||| ",
                    structure->readStructures_[j].buffer_[i].whiteQueens_,
                    structure->readStructures_[j].buffer_[i].whitePawns_,
                    structure->readStructures_[j].buffer_[i].blackQueens_,
                    structure->readStructures_[j].buffer_[i].blackPawns_,
                    structure->readStructures_[j].buffer_[i].metadata_);
            }
            printf("\n\n");
        }
    }
    __syncwarp(activeMask);
}


D void PrintShmResultsForBoard(const unsigned &fieldId, const ResultLegalActionSpace *const structure) {
    const auto activeMask = __activemask();
    __syncwarp(activeMask);
    if (fieldId ==0) {
        printf("Field: %u read structure: %u ::", fieldId, structure->size_);
        for (int i = 0; i < structure->size_; ++i) {
            printf("%u %u %u %u %u ||| ",
                structure->buffer_[i].whiteQueens_,
                structure->buffer_[i].whitePawns_,
                structure->buffer_[i].blackQueens_,
                structure->buffer_[i].blackPawns_,
                structure->buffer_[i].metadata_);
        }
        printf("\n\n\n");
    }
    __syncwarp(activeMask);
}