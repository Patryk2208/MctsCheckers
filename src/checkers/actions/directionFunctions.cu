//
// Created by patryk on 12/31/25.
//

#include <checkers/actions/directionFunctions.cuh>

D unsigned GetTopLeftDirection::GetId(const unsigned &fieldId) {
    //to get top left we add 3 to a valid field, or 4 when we are in an odd row
    //the field is valid <=> (fieldId % 4 != 0 or fieldId / 4 % 2 == 1) and fieldId < 28(not top row)
    const auto isRowOdd = (fieldId >> 2) & 1; //same as / 4
    const auto column = fieldId & 3; //same as % 4
    const unsigned isValid = (column != 0 | isRowOdd) & (fieldId < 28);
    return fieldId + isValid * (3 + isRowOdd);
}

D unsigned GetTopRightDirection::GetId(const unsigned &fieldId) {
    //to get top right we add 4 to a valid field, or 5 when we are in an odd row
    //the field is valid <=> (fieldId % 4 != 3 or fieldId / 4 % 2 == 0) and fieldId < 28(not top row)
    const auto isRowEven = ~(fieldId >> 2) & 1;
    const auto column = fieldId & 3;
    const unsigned isValid = (column != 3 | isRowEven) & (fieldId < 28);
    return fieldId + isValid * (4 + !isRowEven);
}

D unsigned GetBottomLeftDirection::GetId(const unsigned &fieldId) {
    //to get bottom left we subtract 4 from a valid field, or 5 when we are in an even row
    //the field is valid <=> (fieldId % 4 != 0 or fieldId / 4 % 2 == 1) and fieldId > 3 (not bottom row)
    const auto isRowOdd = (fieldId >> 2) & 1;
    const auto column = fieldId & 3;
    const unsigned isValid = (column != 0 | isRowOdd) & (fieldId > 3);
    return fieldId - isValid * (4 + !isRowOdd);
}

D unsigned GetBottomRightDirection::GetId(const unsigned &fieldId) {
    //to get bottom right we subtract 3 from a valid field, or 4 when we are in an even row
    //the field is valid <=> (fieldId % 4 != 3 or fieldId / 4 % 2 == 0) and fieldId > 3 (not bottom row)
    const auto isRowEven = ~(fieldId >> 2) & 1;
    const auto column = fieldId & 3;
    const unsigned isValid = (column != 3 | isRowEven) & (fieldId > 3);
    return fieldId - isValid * (3 + isRowEven);
}

//Simple masks to determine the direction of the last move,
//we set to the direction in which we just moved, NOT the one from which we arrived to the neighboring field
D Mask GetTopLeftDirection::GetDirectionSymbol() {
    return 0x00010000;
}

D Mask GetTopRightDirection::GetDirectionSymbol() {
    return 0x00020000;
}

D Mask GetBottomLeftDirection::GetDirectionSymbol() {
    return 0x00040000;
}

D Mask GetBottomRightDirection::GetDirectionSymbol() {
    return 0x00080000;
}

//simple functions that check if for the current move, we can take in that direction,
//only for queen takes to avoid taking 2 pieces along the same diagonal in 2 directions
D bool GetTopLeftDirection::CanTakeInThatDirection(const BoardMapMetadata &metadata) {
    auto a = metadata & 0x000f0000;
    auto b = GetBottomRightDirection::GetDirectionSymbol();
    return (metadata & 0x000f0000) != GetBottomRightDirection::GetDirectionSymbol();
}

D bool GetTopRightDirection::CanTakeInThatDirection(const BoardMapMetadata &metadata) {
    return (metadata & 0x000f0000) != GetBottomLeftDirection::GetDirectionSymbol();
}

D bool GetBottomLeftDirection::CanTakeInThatDirection(const BoardMapMetadata &metadata) {
    return (metadata & 0x000f0000) != GetTopRightDirection::GetDirectionSymbol();
}

D bool GetBottomRightDirection::CanTakeInThatDirection(const BoardMapMetadata &metadata) {
    return (metadata & 0x000f0000) != GetTopLeftDirection::GetDirectionSymbol();
}
