//
// Created by patryk on 12/31/25.
//

#include <checkers/actions/directionFunctions.cuh>

//todo test for each fieldId

unsigned GetTopLeftDirection::GetId(const unsigned &fieldId) {
    //to get top left we add 3 to a valid field, or 4 when we are in an odd row
    //the field is valid <=> (fieldId % 4 != 0 or fieldId / 4 % 2 == 1) and fieldId < 28(not top row)
    const auto isRowOdd = (fieldId >> 2) & 1; //same as / 4
    const auto column = fieldId & 3; //same as % 4
    const unsigned isValid = (column != 0 | isRowOdd) & (fieldId < 28);
    return fieldId + isValid * (3 + isRowOdd);
}

unsigned GetTopRightDirection::GetId(const unsigned &fieldId) {
    //to get top right we add 4 to a valid field, or 5 when we are in an odd row
    //the field is valid <=> (fieldId % 4 != 3 or fieldId / 4 % 2 == 0) and fieldId < 28(not top row)
    const auto isRowEven = ~(fieldId >> 2) & 1;
    const auto column = fieldId & 3;
    const unsigned isValid = (column != 3 | isRowEven) & (fieldId < 28);
    return fieldId + isValid * (4 + !isRowEven);
}

unsigned GetBottomLeftDirection::GetId(const unsigned &fieldId) {
    //to get bottom left we subtract 4 from a valid field, or 5 when we are in an even row
    //the field is valid <=> (fieldId % 4 != 0 or fieldId / 4 % 2 == 1) and fieldId > 3 (not bottom row)
    const auto isRowOdd = (fieldId >> 2) & 1;
    const auto column = fieldId & 3;
    const unsigned isValid = (column != 0 | isRowOdd) & (fieldId > 3);
    return fieldId - isValid * (4 + !isRowOdd);
}

unsigned GetBottomRightDirection::GetId(const unsigned &fieldId) {
    //to get bottom right we subtract 3 from a valid field, or 4 when we are in an even row
    //the field is valid <=> (fieldId % 4 != 3 or fieldId / 4 % 2 == 0) and fieldId > 3 (not bottom row)
    const auto isRowEven = ~(fieldId >> 2) & 1;
    const auto column = fieldId & 3;
    const unsigned isValid = (column != 0 | isRowEven) & (fieldId > 3);
    return fieldId - isValid * (3 + isRowEven);
}


template<typename Direction, Players player>
__device__ void DirectionGetQueenTakeMoves(
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
__device__ void DirectionGetPawnTakeMoves(
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
__device__ void DirectionGetQueenNormalMoves(
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
__device__ void DirectionGetPawnNormalMoves(
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
