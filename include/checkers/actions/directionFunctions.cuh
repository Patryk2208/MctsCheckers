//
// Created by patryk on 12/30/25.
//

#ifndef MCTS_CHECKERS_DIRECTIONFUNCTIONS_CUH
#define MCTS_CHECKERS_DIRECTIONFUNCTIONS_CUH

#include <checkers/actions/helperFunctions.cuh>
#include <checkers/actions/shmStructure.cuh>

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
    unsigned fieldId,
    CheckersState& next,
    LegalTakeMovesSubStateMap& boardSubStateMap,
    bool& wasPushed) {
    static_assert(IsValidDirection<Direction>, "Must be one of the Direction structs");

    const Mask fieldMask = 1 << fieldId;

    BoardMap pawns;
    BoardMap queens;
    BoardMap opponentPawns;
    BoardMap opponentQueens;

    auto currentTakenFieldId = Direction::GetId(fieldId);
    auto currentTakenMask = GetMask(fieldId, currentTakenFieldId);
    while (currentTakenMask) {
        auto potentialNewSubState = next;
        AssignSides<player>(potentialNewSubState, pawns, queens, opponentPawns, opponentQueens);

        if (opponentPawns & currentTakenMask || opponentQueens & currentTakenMask) {
            auto currentDestinationFieldId = Direction::GetId(currentTakenFieldId);
            auto currentDestinationMask = GetMask(currentTakenFieldId, currentDestinationFieldId);
            while (currentDestinationMask) {
                potentialNewSubState = next;
                AssignSides<player>(potentialNewSubState, pawns, queens, opponentPawns, opponentQueens);

                if (CheckQueenTakeMoveForMask(fieldMask, currentTakenMask, currentDestinationMask, pawns, queens, opponentPawns, opponentQueens)) {
                    boardSubStateMap.writeStructures_[currentDestinationFieldId].WriteToStructure(currentDestinationFieldId, potentialNewSubState);
                    wasPushed = true;
                }
                const auto oldDestinationFieldId = currentDestinationFieldId;
                currentDestinationFieldId = Direction::GetId(currentDestinationFieldId);
                currentDestinationMask = GetMask(oldDestinationFieldId, currentDestinationFieldId);
            }
        }
        if (pawns & currentTakenMask || queens & currentTakenMask) {
            break;
        }
        const auto oldTakenFieldId = currentTakenFieldId;
        currentTakenFieldId = Direction::GetId(currentTakenFieldId);
        currentTakenMask = GetMask(oldTakenFieldId, currentTakenFieldId);
    }
}

template<typename Direction, Players player>
D void DirectionGetPawnTakeMoves(
    unsigned fieldId,
    CheckersState& next,
    LegalTakeMovesSubStateMap& boardSubStateMap,
    bool& wasPushed) {
    static_assert(IsValidDirection<Direction>, "Must be one of the Direction structs");

    const Mask fieldMask = 1 << fieldId;

    BoardMap pawns;
    BoardMap queens;
    BoardMap opponentPawns;
    BoardMap opponentQueens;

    auto takenId = Direction::GetId(fieldId);
    auto takenMask = GetMask(fieldId, takenId);
    auto destinationMask = GetMask(takenId, Direction::GetId(takenId));

    if (takenMask && destinationMask) {
        auto potentialNewSubState = next;
        AssignSides<player>(potentialNewSubState, pawns, queens, opponentPawns, opponentQueens);
        if (CheckPawnTakeMoveForMask(fieldMask, takenMask, destinationMask, pawns, queens, opponentPawns, opponentQueens)) {
            boardSubStateMap.writeStructures_[takenId].WriteToStructure(takenId, potentialNewSubState);
            wasPushed = true;
        }
    }

}

template<typename Direction, Players player>
D void DirectionGetQueenNormalMoves(
    unsigned fieldId,
    CheckersState& next,
    LegalTakeMovesSubStateMap& boardSubStateMap) {
    static_assert(IsValidDirection<Direction>, "Must be one of the Direction structs");

    const Mask fieldMask = 1 << fieldId;

    BoardMap pawns;
    BoardMap queens;
    BoardMap opponentPawns;
    BoardMap opponentQueens;

    auto currentDestinationFieldId = Direction::GetId(fieldId);
    auto currentDestinationMask = GetMask(fieldId, currentDestinationFieldId);
    while (currentDestinationMask) {
        auto potentialNewSubState = next;
        AssignSides<player>(potentialNewSubState, pawns, queens, opponentPawns, opponentQueens);

        if (
            pawns & currentDestinationMask ||
            opponentPawns & currentDestinationMask ||
            queens & currentDestinationMask ||
            opponentQueens & currentDestinationMask
            ) {
            break;
        }

        if (CheckQueenNormalMoveForMask(fieldMask, currentDestinationMask, pawns, queens, opponentPawns, opponentQueens)) {
            boardSubStateMap.writeStructures_[currentDestinationFieldId].WriteToStructure(currentDestinationFieldId, potentialNewSubState);
        }
    }
}

template<typename Direction, Players player>
D void DirectionGetPawnNormalMoves(
    unsigned fieldId,
    CheckersState& next,
    LegalTakeMovesSubStateMap& boardSubStateMap) {
    static_assert(IsValidDirection<Direction>, "Must be one of the Direction structs");

    const Mask fieldMask = 1 << fieldId;

    BoardMap pawns;
    BoardMap queens;
    BoardMap opponentPawns;
    BoardMap opponentQueens;

    auto destinationId = Direction::GetId(fieldId);
    auto destinationMask = GetMask(fieldId, destinationId);
    if (destinationMask) {
        auto potentialNewSubState = next;
        AssignSides<player>(potentialNewSubState, pawns, queens, opponentPawns, opponentQueens);
        if (CheckPawnNormalMoveForMask(fieldMask, destinationMask, pawns, queens, opponentPawns, opponentQueens)) {
            boardSubStateMap.writeStructures_[destinationId].WriteToStructure(destinationId, potentialNewSubState);
        }
    }
}



#endif //MCTS_CHECKERS_DIRECTIONFUNCTIONS_CUH