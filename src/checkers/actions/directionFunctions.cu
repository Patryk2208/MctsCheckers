//
// Created by patryk on 12/31/25.
//

#include <checkers/actions/directionFunctions.cuh>


unsigned GetTopLeftDirection::GetId(unsigned fieldId) {

}

Mask GetTopLeftDirection::GetMask(unsigned fieldId) {

}


unsigned GetTopRightDirection::GetId(unsigned fieldId) {

}

Mask GetTopRightDirection::GetMask(unsigned fieldId) {

}


unsigned GetBottomLeftDirection::GetId(unsigned fieldId) {

}

Mask GetBottomLeftDirection::GetMask(unsigned fieldId) {

}


unsigned GetBottomRightDirection::GetId(unsigned fieldId) {

}

Mask GetBottomRightDirection::GetMask(unsigned fieldId) {

}


template<typename Direction, Players player>
__device__ void DirectionGetQueenTakeMoves(
    unsigned fieldId,
    CheckersState& next,
    LegalTakeMovesSubStateMap& boardSubStateMap,
    bool& wasPushed) {
    static_assert(IsValidDirection<Direction>, "Must be one of the Direction structs");

    Mask fieldMask = 1 << fieldId;

    BoardMap pawns;
    BoardMap queens;
    BoardMap opponentPawns;
    BoardMap opponentQueens;

    auto currentTakenFieldId = Direction::GetId(fieldId);
    auto currentTakenMask = Direction::GetMask(fieldId);
    while (currentTakenMask) {
        auto potentialNewSubState = next;
        AssignSides<player>(potentialNewSubState, pawns, queens, opponentPawns, opponentQueens);

        if (opponentPawns & currentTakenMask || opponentQueens & currentTakenMask) {
            auto currentDestinationFieldId = Direction::GetId(currentTakenFieldId);
            auto currentDestinationMask = Direction::GetMask(currentTakenFieldId);
            while (currentDestinationMask) {
                if (CheckQueenTakeMoveForMask(fieldMask, currentTakenMask, currentDestinationMask, pawns, queens, opponentPawns, opponentQueens)) {
                    boardSubStateMap.writeStructures_[currentDestinationFieldId].WriteToStructure(potentialNewSubState);
                    wasPushed = true;
                }
                currentDestinationFieldId = Direction::GetId(currentDestinationFieldId);
                currentDestinationMask = Direction::GetMask(currentDestinationFieldId);
            }
        }
        if (pawns & currentTakenMask || queens & currentTakenMask) {
            break;
        }
        currentTakenFieldId = Direction::GetId(currentTakenFieldId);
        currentTakenMask = Direction::GetMask(currentTakenFieldId);
    }
}

template<typename Direction, Players player>
__device__ void DirectionGetPawnTakeMoves(
    unsigned fieldId,
    CheckersState& next,
    LegalTakeMovesSubStateMap& boardSubStateMap,
    bool& wasPushed) {
    static_assert(IsValidDirection<Direction>, "Must be one of the Direction structs");

    Mask fieldMask = 1 << fieldId;

    BoardMap pawns;
    BoardMap queens;
    BoardMap opponentPawns;
    BoardMap opponentQueens;

    auto takenId = Direction::GetId(fieldId);
    auto takenMask = Direction::GetMask(fieldId);
    auto destinationMask = Direction::GetMask(takenId);

    if (takenMask && destinationMask) {
        auto potentialNewSubState = next;
        AssignSides<player>(potentialNewSubState, pawns, queens, opponentPawns, opponentQueens);
        if (CheckPawnTakeMoveForMask(fieldMask, takenMask, destinationMask, pawns, queens, opponentPawns, opponentQueens)) {
            boardSubStateMap.writeStructures_[takenId].WriteToStructure(potentialNewSubState);
            wasPushed = true;
        }
    }

}

template<typename Direction, Players player>
__device__ void DirectionGetQueenNormalMoves(
    unsigned fieldId,
    CheckersState& next,
    LegalTakeMovesSubStateMap& boardSubStateMap) {
    static_assert(IsValidDirection<Direction>, "Must be one of the Direction structs");

    Mask fieldMask = 1 << fieldId;

    BoardMap pawns;
    BoardMap queens;
    BoardMap opponentPawns;
    BoardMap opponentQueens;

    auto currentDestinationFieldId = Direction::GetId(fieldId);
    auto currentDestinationMask = Direction::GetMask(fieldId);
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
            boardSubStateMap.writeStructures_[currentDestinationFieldId].WriteToStructure(potentialNewSubState);
        }
    }
}

template<typename Direction, Players player>
__device__ void DirectionGetPawnNormalMoves(
    unsigned fieldId,
    CheckersState& next,
    LegalTakeMovesSubStateMap& boardSubStateMap) {
    static_assert(IsValidDirection<Direction>, "Must be one of the Direction structs");

    Mask fieldMask = 1 << fieldId;

    BoardMap pawns;
    BoardMap queens;
    BoardMap opponentPawns;
    BoardMap opponentQueens;

    auto destinationId = Direction::GetId(fieldId);
    auto destinationMask = Direction::GetMask(fieldId);
    if (destinationMask) {
        auto potentialNewSubState = next;
        AssignSides<player>(potentialNewSubState, pawns, queens, opponentPawns, opponentQueens);
        if (CheckPawnNormalMoveForMask(fieldMask, destinationMask, pawns, queens, opponentPawns, opponentQueens)) {
            boardSubStateMap.writeStructures_[destinationId].WriteToStructure(potentialNewSubState);
        }
    }
}
