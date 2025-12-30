//
// Created by patryk on 12/28/25.
//

#include "checkers/actions.cuh"

__global__ void CheckTerminal(int batchSize, BatchSoACheckersState states, float *results, bool *terminal) {
    auto threadId = gridDim.x * blockDim.x + threadIdx.x;
    if (threadId >= batchSize) return;

    //those should be register bound for each thread(board)
    auto whitePawns = states.whitePawns_[threadId];
    auto blackPawns = states.blackPawns_[threadId];
    auto whiteQueens = states.whiteQueens_[threadId];
    auto blackQueens = states.blackQueens_[threadId];
    auto metadata = states.metadata_[threadId];

    //simple terminal position check
    auto whiteLoses = whitePawns + whiteQueens == 0;
    auto blackLoses = blackPawns + blackQueens == 0;
    auto moveCountDraw = (metadata & 0b00001111) == 0b00001111;

    //advanced result check
    //todo calculate some position scores

    //todo write whether terminal and if so, results
}

//todo consider eliminating the IF branches with some ugly conditional numerics
//todo DONE perhaps it's possible to split into 4 phases queen take, pawn take, queen move, pawn move
//todo DONE perhaps it's possible to split each phase's 4 directions into one function
//todo DONE make player a compile time template
__global__ void GetLegalActions(BatchSoACheckersState& states, int batchSize) {
    extern __shared__ void* sharedMemory;
    auto subStateDataStructure = (LegalTakeMovesSubStateMap*)sharedMemory;
    auto resultActionSpace = (ResultLegalActionSpace*)(sharedMemory + batchSize * sizeof(LegalTakeMovesSubStateMap));
    //todo shm init
    __syncthreads();

    auto threadId = gridDim.x * blockDim.x + threadIdx.x;
    unsigned int fieldId = threadId % 32;
    auto boardId = threadId / 32;

    auto boardSubStateMap = subStateDataStructure[boardId];
    auto fieldSubStateReadStructure = boardSubStateMap.readStructures_[fieldId];
    auto boardResultActionSpace = resultActionSpace[boardId];

    //todo first we wanna populate the readStructures somehow only those fields where there is a pawn/queen

    //we are not diverging here, because each warp is one board and the player is common across fields in one board
    if (states.metadata_[boardId] & 0b10000000) {
        DiscoverActions<BlackPlayer>(fieldId, boardSubStateMap, fieldSubStateReadStructure, boardResultActionSpace);
    }
    else {
        DiscoverActions<WhitePlayer>(fieldId, boardSubStateMap, fieldSubStateReadStructure, boardResultActionSpace);
    }

    __syncwarp();
    //todo now return the space of possible actions

}

template<Players player>
__device__ void DiscoverActions(
    const unsigned &fieldId,
    LegalTakeMovesSubStateMap& boardSubStateMap,
    SubStatesPerFieldStructure& fieldSubStateReadStructure,
    ResultLegalActionSpace& boardResultActionSpace) {
    //take-moves section
    GetLegalQueenTakeMoves<player>(fieldId, boardSubStateMap, fieldSubStateReadStructure, boardResultActionSpace);
    GetLegalPawnTakeMoves<player>(fieldId, boardSubStateMap, fieldSubStateReadStructure, boardResultActionSpace);

    if (boardResultActionSpace.size_ == 0) {
        //normal moves section
        //todo we might wanna repopulate the read structure and clear structures altogether
        GetLegalQueenNormalMoves<player>(fieldId, boardSubStateMap, fieldSubStateReadStructure, boardResultActionSpace);
        GetLegalPawnNormalMoves<player>(fieldId, boardSubStateMap, fieldSubStateReadStructure, boardResultActionSpace);
    }
}

template<Players player>
__device__ void GetLegalQueenTakeMoves(
    const unsigned &fieldId,
    LegalTakeMovesSubStateMap& boardSubStateMap,
    SubStatesPerFieldStructure& fieldSubStateReadStructure,
    ResultLegalActionSpace& boardResultActionSpace) {

    auto roundCounter = 0;
    while (true) {
        //round start
        auto wasPushedSomewhereElse = false;
        while (true) {
            CheckersState next;
            if (!fieldSubStateReadStructure.ReadNextFromStructure(next)) {
                break;
            }
            auto activeWarps = __activemask();
            DirectionGetQueenTakeMoves<GetTopLeftDirection, player>(fieldId, next, boardSubStateMap, wasPushedSomewhereElse);
            __syncwarp(activeWarps);
            DirectionGetQueenTakeMoves<GetTopRightDirection, player>(fieldId, next, boardSubStateMap, wasPushedSomewhereElse);
            __syncwarp(activeWarps);
            DirectionGetQueenTakeMoves<GetBottomLeftDirection, player>(fieldId, next, boardSubStateMap, wasPushedSomewhereElse);
            __syncwarp(activeWarps);
            DirectionGetQueenTakeMoves<GetBottomRightDirection, player>(fieldId, next, boardSubStateMap, wasPushedSomewhereElse);
            __syncwarp(activeWarps);
            if (!wasPushedSomewhereElse && roundCounter > 0) {
                CompleteQueenMoveFromSubTakeMoveState(next);
                boardResultActionSpace.AppendToStructure(next);
            }
        }
        //todo setup the data structure after the round
        if (!__any_sync(0xffffffff, wasPushedSomewhereElse)) break;
        ++roundCounter;
    }
}

template<Players player>
__device__ void GetLegalPawnTakeMoves(
    const unsigned &fieldId,
    LegalTakeMovesSubStateMap& boardSubStateMap,
    SubStatesPerFieldStructure& fieldSubStateReadStructure,
    ResultLegalActionSpace& boardResultActionSpace) {

    auto roundCounter = 0;
    while (true) {
        //round start
        auto wasPushedSomewhereElse = false;
        while (true) {
            CheckersState next;
            if (!fieldSubStateReadStructure.ReadNextFromStructure(next)) {
                break;
            }
            auto activeWarps = __activemask();
            DirectionGetPawnTakeMoves<GetTopLeftDirection>, player(fieldId, next, boardSubStateMap, wasPushedSomewhereElse);
            __syncwarp(activeWarps);
            DirectionGetPawnTakeMoves<GetTopRightDirection, player>(fieldId, next, boardSubStateMap, wasPushedSomewhereElse);
            __syncwarp(activeWarps);
            DirectionGetPawnTakeMoves<GetBottomLeftDirection, player>(fieldId, next, boardSubStateMap, wasPushedSomewhereElse);
            __syncwarp(activeWarps);
            DirectionGetPawnTakeMoves<GetBottomRightDirection, player>(fieldId, next, boardSubStateMap, wasPushedSomewhereElse);
            __syncwarp(activeWarps);
            if (!wasPushedSomewhereElse && roundCounter > 0) {
                CompletePawnMoveFromSubTakeMoveState(next);
                boardResultActionSpace.AppendToStructure(next);
            }
        }
        //todo setup the data structure after the round
        if (!__any_sync(0xffffffff, wasPushedSomewhereElse)) break;
        ++roundCounter;
    }
}

template<Players player>
__device__ void GetLegalQueenNormalMoves(
    const unsigned &fieldId,
    LegalTakeMovesSubStateMap& boardSubStateMap,
    SubStatesPerFieldStructure& fieldSubStateReadStructure,
    ResultLegalActionSpace& boardResultActionSpace) {

    CheckersState next;
    if (fieldSubStateReadStructure.ReadNextFromStructure(next)) {
        auto activeWarps = __activemask();

        DirectionGetQueenNormalMoves<GetTopLeftDirection, player>(fieldId, next, boardSubStateMap);
        __syncwarp(activeWarps);
        DirectionGetQueenNormalMoves<GetTopRightDirection, player>(fieldId, next, boardSubStateMap);
        __syncwarp(activeWarps);
        DirectionGetQueenNormalMoves<GetBottomLeftDirection, player>(fieldId, next, boardSubStateMap);
        __syncwarp(activeWarps);
        DirectionGetQueenNormalMoves<GetBottomRightDirection, player>(fieldId, next, boardSubStateMap);
        __syncwarp(activeWarps);
    }
    //todo setup the data structure after the round
    __syncwarp(0xffffffff);
    while (true) {
        if (!fieldSubStateReadStructure.ReadNextFromStructure(next)) {
            break;
        }
        boardResultActionSpace.AppendToStructure(next);
    }
}

template<Players player>
__device__ void GetLegalPawnNormalMoves(
    const unsigned &fieldId,
    LegalTakeMovesSubStateMap& boardSubStateMap,
    SubStatesPerFieldStructure& fieldSubStateReadStructure,
    ResultLegalActionSpace& boardResultActionSpace) {

    CheckersState next;
    if (fieldSubStateReadStructure.ReadNextFromStructure(next)) {
        auto activeWarps = __activemask();

        if constexpr (player == WhitePlayer) {
            DirectionGetPawnNormalMoves<GetTopLeftDirection, player>(fieldId, next, boardSubStateMap);
            __syncwarp(activeWarps);
            DirectionGetPawnNormalMoves<GetTopRightDirection, player>(fieldId, next, boardSubStateMap);
            __syncwarp(activeWarps);
        }
        else {
            DirectionGetPawnNormalMoves<GetBottomLeftDirection, player>(fieldId, next, boardSubStateMap);
            __syncwarp(activeWarps);
            DirectionGetPawnNormalMoves<GetBottomRightDirection, player>(fieldId, next, boardSubStateMap);
            __syncwarp(activeWarps);
        }
    }
    __syncwarp(0xffffffff);
    //todo setup the data structure after the round
    while (true) {
        if (!fieldSubStateReadStructure.ReadNextFromStructure(next)) {
            break;
        }
        boardResultActionSpace.AppendToStructure(next);
    }
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

//helper functions

__device__ bool CheckQueenTakeMoveForMask(
    const Mask &originMask,
    const Mask &takenMask,
    const Mask &destinationMask,
    BoardMap &pawns,
    BoardMap &queens,
    BoardMap &opponentPawns,
    BoardMap &opponentQueens) {
    //todo
}

__device__ bool CheckPawnTakeMoveForMask(
    const Mask &originMask,
    const Mask &takenMask,
    const Mask& destinationMask,
    BoardMap &pawns,
    BoardMap &queens,
    BoardMap& opponentPawns,
    BoardMap& opponentQueens) {
    auto isOpponentTaken = ((opponentPawns & takenMask) || (opponentQueens & takenMask));
    auto isDestinationFree = !(opponentPawns & destinationMask || opponentQueens & destinationMask || pawns & destinationMask || queens & destinationMask);
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
    //todo
}

__device__ bool CheckPawnNormalMoveForMask(
    const Mask &originMask,
    const Mask& destinationMask,
    BoardMap &pawns,
    BoardMap &queens,
    BoardMap& opponentPawns,
    BoardMap& opponentQueens) {
    auto isDestinationFree = !(pawns & destinationMask || opponentPawns & destinationMask || queens & destinationMask || opponentQueens & destinationMask);
    if (isDestinationFree) {
        pawns &= !originMask;
        pawns |= destinationMask;
    }
}


__device__ void CompletePawnMoveFromSubTakeMoveState(CheckersState &state) {
    state.metadata_ ^= 0b10000000; //changing the turn
    state.metadata_ &= 0b11110000; //resetting the draw count
    //todo promotion
}

__device__ void CompletePawnNormalMove(CheckersState &state) {
    state.metadata_ ^= 0b10000000; //changing the turn
    state.metadata_ &= 0b11110000; //resetting the draw count
    //todo promotion
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