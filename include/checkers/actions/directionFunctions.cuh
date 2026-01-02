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
};

struct GetTopRightDirection {
    D static unsigned GetId(const unsigned &fieldId);
};

struct GetBottomLeftDirection {
    D static unsigned GetId(const unsigned &fieldId);
};

struct GetBottomRightDirection {
    D static unsigned GetId(const unsigned &fieldId);
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

    const Mask fieldMask = 1 << fieldId;

    auto currentTakenFieldId = Direction::GetId(fieldId);
    auto currentTakenMask = GetMask(fieldId, currentTakenFieldId);
    while (currentTakenMask) {
        BoardMap* pawns = nullptr;
        BoardMap* queens = nullptr;
        BoardMap* opponentPawns = nullptr;
        BoardMap* opponentQueens = nullptr;
        auto potentialNewSubState = next;
        AssignSides<player>(potentialNewSubState, pawns, queens, opponentPawns, opponentQueens);

        if (*opponentPawns & currentTakenMask || *opponentQueens & currentTakenMask) {
            auto currentDestinationFieldId = Direction::GetId(currentTakenFieldId);
            auto currentDestinationMask = GetMask(currentTakenFieldId, currentDestinationFieldId);
            while (currentDestinationMask) {
                potentialNewSubState = next;
                AssignSides<player>(potentialNewSubState, pawns, queens, opponentPawns, opponentQueens);

                if (CheckQueenTakeMoveForMask(fieldMask, currentTakenMask, currentDestinationMask, pawns, queens, opponentPawns, opponentQueens)) {
                    boardSubStateMap->WriteToStructure(fieldId, currentDestinationFieldId, potentialNewSubState);
                    wasPushed = true;
                }
                const auto oldDestinationFieldId = currentDestinationFieldId;
                currentDestinationFieldId = Direction::GetId(currentDestinationFieldId);
                currentDestinationMask = GetMask(oldDestinationFieldId, currentDestinationFieldId);
            }
        }
        if (*pawns & currentTakenMask || *queens & currentTakenMask) {
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

        if (
            *pawns & currentDestinationMask ||
            *opponentPawns & currentDestinationMask ||
            *queens & currentDestinationMask ||
            *opponentQueens & currentDestinationMask
            ) {
            break;
        }

        if (CheckQueenNormalMoveForMask(fieldMask, currentDestinationMask, pawns, queens, opponentPawns, opponentQueens)) {
            boardSubStateMap->WriteToStructure(fieldId, currentDestinationFieldId, potentialNewSubState);
        }
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