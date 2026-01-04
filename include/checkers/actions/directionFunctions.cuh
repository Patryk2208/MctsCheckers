//
// Created by patryk on 12/30/25.
//

#ifndef MCTS_CHECKERS_DIRECTIONFUNCTIONS_CUH
#define MCTS_CHECKERS_DIRECTIONFUNCTIONS_CUH

#include <checkers/actions/helperFunctions.cuh>
#include <checkers/actions/shmStructure.cuh>

#include "cudaUtils/intrinsicsWrappers.cuh"

struct GetTopLeftDirection {
    D static unsigned GetId(const unsigned &fieldId);
    D static Mask GetDirectionSymbol();
    D static bool CanTakeInThatDirection(const BoardMapMetadata& metadata);
};

struct GetTopRightDirection {
    D static unsigned GetId(const unsigned &fieldId);
    D static Mask GetDirectionSymbol();
    D static bool CanTakeInThatDirection(const BoardMapMetadata& metadata);
};

struct GetBottomLeftDirection {
    D static unsigned GetId(const unsigned &fieldId);
    D static Mask GetDirectionSymbol();
    D static bool CanTakeInThatDirection(const BoardMapMetadata& metadata);
};

struct GetBottomRightDirection {
    D static unsigned GetId(const unsigned &fieldId);
    D static Mask GetDirectionSymbol();
    D static bool CanTakeInThatDirection(const BoardMapMetadata& metadata);
};

template <typename Dir>
constexpr bool IsValidDirection =
    std::is_same_v<Dir, GetTopLeftDirection> ||
    std::is_same_v<Dir, GetTopRightDirection> ||
    std::is_same_v<Dir, GetBottomLeftDirection> ||
    std::is_same_v<Dir, GetBottomRightDirection>;


template<typename Direction, Players player>
D void DirectionGetQueenTakeMoves(
    const unsigned &fieldId,
    const CheckersState &next,
    LegalMovesSubStateMap *const boardSubStateMap,
    bool& wasPushed) {
    static_assert(IsValidDirection<Direction>, "Must be one of the Direction structs");

    auto res = Direction::CanTakeInThatDirection(next.metadata_);
    if (!Direction::CanTakeInThatDirection(next.metadata_)) {
        return;
    }

    const Mask fieldMask = 1 << fieldId;

    auto currentTakenFieldId = Direction::GetId(fieldId);
    auto currentTakenMask = GetMask(fieldId, currentTakenFieldId);
    auto cannotTakeFurther = false;
    while (currentTakenMask && !cannotTakeFurther) {
        BoardMap* pawns = nullptr;
        BoardMap* queens = nullptr;
        BoardMap* opponentPawns = nullptr;
        BoardMap* opponentQueens = nullptr;
        auto potentialNewSubState = next;
        AssignSides<player>(potentialNewSubState, pawns, queens, opponentPawns, opponentQueens);

        if (*opponentPawns & currentTakenMask || *opponentQueens & currentTakenMask) {
            cannotTakeFurther = true;
            //first only such queen take moves that enable continuation
            auto continuationMoveCount = 0;
            auto currentDestinationFieldId = Direction::GetId(currentTakenFieldId);
            auto currentDestinationMask = GetMask(currentTakenFieldId, currentDestinationFieldId);
            while (currentDestinationMask) {
                potentialNewSubState = next;
                AssignSides<player>(potentialNewSubState, pawns, queens, opponentPawns, opponentQueens);

                if (CheckQueenTakeMoveForMask(fieldMask, currentTakenMask, currentDestinationMask, pawns, queens, opponentPawns, opponentQueens)) {
                    potentialNewSubState.metadata_ &= 0x11101111;
                    potentialNewSubState.metadata_ |= Direction::GetDirectionSymbol();
                    if (CheckForQueenContinuation(currentDestinationFieldId, pawns, queens, opponentPawns, opponentQueens, &potentialNewSubState.metadata_)) {
                        boardSubStateMap->WriteToStructure(fieldId, currentDestinationFieldId, potentialNewSubState);
                        wasPushed = true;
                        ++continuationMoveCount;
                    }
                }
                else {
                    break;
                }
                const auto oldDestinationFieldId = currentDestinationFieldId;
                currentDestinationFieldId = Direction::GetId(currentDestinationFieldId);
                currentDestinationMask = GetMask(oldDestinationFieldId, currentDestinationFieldId);
            }
            if (continuationMoveCount > 0) break;

            currentDestinationFieldId = Direction::GetId(currentTakenFieldId);
            currentDestinationMask = GetMask(currentTakenFieldId, currentDestinationFieldId);
            while (currentDestinationMask) {
                potentialNewSubState = next;
                AssignSides<player>(potentialNewSubState, pawns, queens, opponentPawns, opponentQueens);

                if (CheckQueenTakeMoveForMask(fieldMask, currentTakenMask, currentDestinationMask, pawns, queens, opponentPawns, opponentQueens)) {
                    potentialNewSubState.metadata_ &= 0x11101111;
                    potentialNewSubState.metadata_ |= Direction::GetDirectionSymbol();
                    boardSubStateMap->WriteToStructure(fieldId, currentDestinationFieldId, potentialNewSubState);
                    wasPushed = true;
                }
                else {
                    break;
                }
                const auto oldDestinationFieldId = currentDestinationFieldId;
                currentDestinationFieldId = Direction::GetId(currentDestinationFieldId);
                currentDestinationMask = GetMask(oldDestinationFieldId, currentDestinationFieldId);
            }
        }
        else if (*pawns & currentTakenMask || *queens & currentTakenMask) {
            break;
        }
        const auto oldTakenFieldId = currentTakenFieldId;
        currentTakenFieldId = Direction::GetId(currentTakenFieldId);
        currentTakenMask = GetMask(oldTakenFieldId, currentTakenFieldId);
    }
}

template<typename Direction, Players player>
D void DirectionGetPawnTakeMoves(
    const unsigned &fieldId,
    const CheckersState &next,
    LegalMovesSubStateMap *const boardSubStateMap,
    bool& wasPushed) {
    static_assert(IsValidDirection<Direction>, "Must be one of the Direction structs");

    const Mask fieldMask = 1 << fieldId;

    const auto takenId = Direction::GetId(fieldId);
    const auto takenMask = GetMask(fieldId, takenId);
    const auto destinationId = Direction::GetId(takenId);
    const auto destinationMask = GetMask(takenId, destinationId);

    if (takenMask && destinationMask) {
        BoardMap* pawns = nullptr;
        BoardMap* queens = nullptr;
        BoardMap* opponentPawns = nullptr;
        BoardMap* opponentQueens = nullptr;
        auto potentialNewSubState = next;
        AssignSides<player>(potentialNewSubState, pawns, queens, opponentPawns, opponentQueens);
        if (CheckPawnTakeMoveForMask(fieldMask, takenMask, destinationMask, pawns, queens, opponentPawns, opponentQueens)) {
            boardSubStateMap->WriteToStructure(fieldId, destinationId, potentialNewSubState);
            wasPushed = true;
        }
    }

}

template<typename Direction, Players player>
D void DirectionGetQueenNormalMoves(
    const unsigned &fieldId,
    const CheckersState &next,
    LegalMovesSubStateMap *const boardSubStateMap) {
    static_assert(IsValidDirection<Direction>, "Must be one of the Direction structs");

    const Mask fieldMask = 1 << fieldId;

    auto currentDestinationFieldId = Direction::GetId(fieldId);
    auto currentDestinationMask = GetMask(fieldId, currentDestinationFieldId);
    while (currentDestinationMask) {
        BoardMap* pawns = nullptr;
        BoardMap* queens = nullptr;
        BoardMap* opponentPawns = nullptr;
        BoardMap* opponentQueens = nullptr;
        auto potentialNewSubState = next;
        AssignSides<player>(potentialNewSubState, pawns, queens, opponentPawns, opponentQueens);
        if (CheckQueenNormalMoveForMask(fieldMask, currentDestinationMask, pawns, queens, opponentPawns, opponentQueens)) {
            boardSubStateMap->WriteToStructure(fieldId, currentDestinationFieldId, potentialNewSubState);
        }
        const auto oldDestinationFieldId = currentDestinationFieldId;
        currentDestinationFieldId = Direction::GetId(currentDestinationFieldId);
        currentDestinationMask = GetMask(oldDestinationFieldId, currentDestinationFieldId);
    }
}

template<typename Direction, Players player>
D void DirectionGetPawnNormalMoves(
    const unsigned &fieldId,
    const CheckersState &next,
    LegalMovesSubStateMap *const boardSubStateMap) {
    static_assert(IsValidDirection<Direction>, "Must be one of the Direction structs");

    const Mask fieldMask = 1 << fieldId;

    auto destinationId = Direction::GetId(fieldId);
    auto destinationMask = GetMask(fieldId, destinationId);
    if (destinationMask) {
        BoardMap* pawns = nullptr;
        BoardMap* queens = nullptr;
        BoardMap* opponentPawns = nullptr;
        BoardMap* opponentQueens = nullptr;
        auto potentialNewSubState = next;
        AssignSides<player>(potentialNewSubState, pawns, queens, opponentPawns, opponentQueens);
        if (CheckPawnNormalMoveForMask(fieldMask, destinationMask, pawns, queens, opponentPawns, opponentQueens)) {
            boardSubStateMap->WriteToStructure(fieldId, destinationId, potentialNewSubState);
        }
    }
}



#endif //MCTS_CHECKERS_DIRECTIONFUNCTIONS_CUH