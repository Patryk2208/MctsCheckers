//
// Created by patryk on 12/30/25.
//

#ifndef MCTS_CHECKERS_HELPERFUNCTIONS_CUH
#define MCTS_CHECKERS_HELPERFUNCTIONS_CUH

#include <cudaUtils/cudaCompatibility.hpp>
#include <checkers/state.hpp>

#include "shmStructure.cuh"

using Mask = unsigned int;

D Mask GetMask(const unsigned& originalFieldId, const unsigned& currentFieldId);

/**
 * Only if we are sure there is our queen at originMask
 */
D bool CheckQueenTakeMoveForMask(
    const Mask &originMask,
    const Mask &takenMask,
    const Mask &destinationMask,
    BoardMap *pawns,
    BoardMap *queens,
    BoardMap *opponentPawns,
    BoardMap *opponentQueens);

D bool CheckForQueenContinuation(
    const unsigned& fieldId,
    BoardMap *pawns,
    BoardMap *queens,
    BoardMap *opponentPawns,
    BoardMap *opponentQueens,
    BoardMapMetadata *metadata
    );

template<typename Direction>
D bool CheckDirectionContinuation(
    const unsigned &fieldId,
    BoardMap *pawns,
    BoardMap *queens,
    BoardMap *opponentPawns,
    BoardMap *opponentQueens) {
    auto currentTakenFieldId = Direction::GetId(fieldId);
    auto currentTakenMask = GetMask(fieldId, currentTakenFieldId);
    while (currentTakenMask) {
        if (*opponentPawns & currentTakenMask || *opponentQueens & currentTakenMask) {
            auto currentDestinationFieldId = Direction::GetId(currentTakenFieldId);
            auto currentDestinationMask = GetMask(currentTakenFieldId, currentDestinationFieldId);
            if (currentDestinationMask &&
                !(*opponentPawns & currentDestinationMask ||
                    *opponentQueens & currentDestinationMask ||
                    *pawns & currentDestinationMask ||
                    *queens & currentDestinationMask)){
                return true;
            }
            return false;
        }
        if (*pawns & currentTakenMask || *queens & currentTakenMask) {
            break;
        }
        const auto oldTakenFieldId = currentTakenFieldId;
        currentTakenFieldId = Direction::GetId(currentTakenFieldId);
        currentTakenMask = GetMask(oldTakenFieldId, currentTakenFieldId);
    }
    return false;
}

/**
 * Only if we are sure there is our pawn at originMask
 */
D bool CheckPawnTakeMoveForMask(
    const Mask &originMask,
    const Mask &takenMask,
    const Mask &destinationMask,
    BoardMap *pawns,
    BoardMap *queens,
    BoardMap *opponentPawns,
    BoardMap *opponentQueens);

/**
 * Only if we are sure there is our queen at originMask
 */
D bool CheckQueenNormalMoveForMask(
    const Mask &originMask,
    const Mask& destinationMask,
    BoardMap *pawns,
    BoardMap *queens,
    BoardMap *opponentPawns,
    BoardMap *opponentQueens);

/**
 * Only if we are sure there is our pawn at originMask
 */
D bool CheckPawnNormalMoveForMask(
    const Mask &originMask,
    const Mask& destinationMask,
    BoardMap *pawns,
    BoardMap *queens,
    BoardMap *opponentPawns,
    BoardMap *opponentQueens);



template<Players player>
D void CompleteQueenTakeMove(const unsigned &fieldId, CheckersState &state) {
    state.metadata_ ^= 0b10000000; //changing the turn
    state.metadata_ &= 0b11110000; //resetting the draw count
    state.metadata_ &= 0b11101111; //resetting the internal direction status
}

template<Players player>
D void CompletePawnTakeMove(const unsigned &fieldId, CheckersState &state) {
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
D void CompleteQueenNormalMove(const unsigned &fieldId, CheckersState &state) {
    state.metadata_ ^= 0b10000000; //changing the turn
    state.metadata_++; //updating the draw count
}

template<Players player>
D void CompletePawnNormalMove(const unsigned &fieldId, CheckersState &state) {
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
D void AssignSides(
    CheckersState &state,
    BoardMap *&pawns,
    BoardMap *&queens,
    BoardMap *&opponentPawns,
    BoardMap *&opponentQueens) {
    if constexpr (player == WhitePlayer) {
        pawns = &state.whitePawns_;
        queens = &state.whiteQueens_;
        opponentPawns = &state.blackPawns_;
        opponentQueens = &state.blackQueens_;
    }
    else {
        pawns = &state.blackPawns_;
        queens = &state.blackPawns_;
        opponentPawns = &state.whitePawns_;
        opponentQueens = &state.whiteQueens_;
    }
}


D void PrintShmStructureForBoard(const unsigned &fieldId, const LegalMovesSubStateMap *structure);
D void PrintShmResultsForBoard(const unsigned &fieldId, const ResultLegalActionSpace *structure);

#endif //MCTS_CHECKERS_HELPERFUNCTIONS_CUH