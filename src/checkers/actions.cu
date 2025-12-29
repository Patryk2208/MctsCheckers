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

__device__ Mask GetTopLeftMask(unsigned fieldId) {
    //todo
}

__device__ Mask GetTopRightMask(unsigned fieldId) {
    //todo
}

__device__ Mask GetBottomLeftMask(unsigned fieldId) {
    //todo
}

__device__ Mask GetBottomRightMask(unsigned fieldId) {
    //todo
}

//todo consider eliminating the IF branches with some ugly conditional numerics
//todo DONE perhaps it's possible to split into 4 phases queen take, pawn take, queen move, pawn move
//todo perhaps it's possible to split each phase's 4 directions into one function
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

    //we can branch the player because all threads in a warp go into the same branch
    auto activePlayer = (states.metadata_[boardId] & 0b10000000) ? BlackPlayer : WhitePlayer;
    //take-moves section
    GetLegalQueenTakeMoves(fieldId, boardSubStateMap, fieldSubStateReadStructure, boardResultActionSpace, activePlayer);

    GetLegalPawnTakeMoves(fieldId, boardSubStateMap, fieldSubStateReadStructure, boardResultActionSpace, activePlayer);

    if (boardResultActionSpace.size_ == 0) {
        //normal moves section
        //todo we might wanna repopulate the read structure and clear structures altogether

        GetLegalQueenNormalMoves(fieldId, boardSubStateMap, fieldSubStateReadStructure, boardResultActionSpace, activePlayer);

        GetLegalPawnNormalMoves(fieldId, boardSubStateMap, fieldSubStateReadStructure, boardResultActionSpace, activePlayer);

    }
    __syncwarp();
    //todo now return the space of possible actions

}

__device__ void GetLegalQueenTakeMoves(
    const unsigned &fieldId,
    LegalTakeMovesSubStateMap& boardSubStateMap,
    SubStatesPerFieldStructure& fieldSubStateReadStructure,
    ResultLegalActionSpace& boardResultActionSpace,
    Players player) {

    auto topLeftFieldId = GetTopLeftId(fieldId);
    auto topRightFieldId = GetTopRightId(fieldId);
    auto bottomLeftFieldId = GetBottomLeftId(fieldId);
    auto bottomRightFieldId = GetBottomRightId(fieldId);

    Mask fieldMask = 1 << fieldId;
    auto topLeftMask = GetTopLeftMask(fieldId);
    auto topRightMask = GetTopRightMask(fieldId);
    auto bottomLeftMask = GetBottomLeftMask(fieldId);
    auto bottomRightMask = GetBottomRightMask(fieldId);

    BoardMap pawns;
    BoardMap queens;
    BoardMap opponentPawns;
    BoardMap opponentQueens;

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
            auto currentTakenFieldId = topLeftFieldId;
            auto currentTakenMask = topLeftMask;
            while (currentTakenMask) {
                auto currentDestinationFieldId = GetTopLeftId(currentTakenFieldId);
                auto currentDestinationMask = GetTopLeftMask(currentTakenFieldId);
                while (currentDestinationMask) {
                    auto potentialNewSubState = next;
                    AssignSides(potentialNewSubState, pawns, queens, opponentPawns, opponentQueens, player);
                    if (CheckQueenTakeMoveForMask(fieldMask, currentTakenMask, currentDestinationMask, pawns, queens, opponentPawns, opponentQueens)) {
                        boardSubStateMap.writeStructures_[currentDestinationFieldId].WriteToStructure(potentialNewSubState);
                        wasPushedSomewhereElse = true;
                    }
                }
            }
            __syncwarp(activeWarps);
            currentTakenFieldId = topRightFieldId;
            currentTakenMask = topRightMask;
            while (currentTakenMask) {
                auto currentDestinationFieldId = GetTopRightId(currentTakenFieldId);
                auto currentDestinationMask = GetTopRightMask(currentTakenFieldId);
                while (currentDestinationMask) {
                    auto potentialNewSubState = next;
                    AssignSides(potentialNewSubState, pawns, queens, opponentPawns, opponentQueens, player);
                    if (CheckQueenTakeMoveForMask(fieldMask, currentTakenMask, currentDestinationMask, pawns, queens, opponentPawns, opponentQueens)) {
                        boardSubStateMap.writeStructures_[currentDestinationFieldId].WriteToStructure(potentialNewSubState);
                        wasPushedSomewhereElse = true;
                    }
                }
            }
            __syncwarp(activeWarps);
            currentTakenFieldId = bottomLeftFieldId;
            currentTakenMask = bottomLeftMask;
            while (currentTakenMask) {
                auto currentDestinationFieldId = GetBottomLeftId(currentTakenFieldId);
                auto currentDestinationMask = GetBottomLeftMask(currentTakenFieldId);
                while (currentDestinationMask) {
                    auto potentialNewSubState = next;
                    AssignSides(potentialNewSubState, pawns, queens, opponentPawns, opponentQueens, player);
                    if (CheckQueenTakeMoveForMask(fieldMask, currentTakenMask, currentDestinationMask, pawns, queens, opponentPawns, opponentQueens)) {
                        boardSubStateMap.writeStructures_[currentDestinationFieldId].WriteToStructure(potentialNewSubState);
                        wasPushedSomewhereElse = true;
                    }
                }
            }
            __syncwarp(activeWarps);
            currentTakenFieldId = bottomRightFieldId;
            currentTakenMask = bottomRightMask;
            while (currentTakenMask) {
                auto currentDestinationFieldId = GetBottomRightId(currentTakenFieldId);
                auto currentDestinationMask = GetBottomRightMask(currentTakenFieldId);
                while (currentDestinationMask) {
                    auto potentialNewSubState = next;
                    AssignSides(potentialNewSubState, pawns, queens, opponentPawns, opponentQueens, player);
                    if (CheckQueenTakeMoveForMask(fieldMask, currentTakenMask, currentDestinationMask, pawns, queens, opponentPawns, opponentQueens)) {
                        boardSubStateMap.writeStructures_[currentDestinationFieldId].WriteToStructure(potentialNewSubState);
                        wasPushedSomewhereElse = true;
                    }
                }
            }
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

__device__ void GetLegalPawnTakeMoves(
    const unsigned &fieldId,
    LegalTakeMovesSubStateMap& boardSubStateMap,
    SubStatesPerFieldStructure& fieldSubStateReadStructure,
    ResultLegalActionSpace& boardResultActionSpace,
    Players player) {

    auto topLeftFieldId = GetTopLeftId(fieldId);
    auto topRightFieldId = GetTopRightId(fieldId);
    auto bottomLeftFieldId = GetBottomLeftId(fieldId);
    auto bottomRightFieldId = GetBottomRightId(fieldId);

    Mask fieldMask = 1 << fieldId;
    auto topLeftMask = GetTopLeftMask(fieldId);
    auto topRightMask = GetTopRightMask(fieldId);
    auto bottomLeftMask = GetBottomLeftMask(fieldId);
    auto bottomRightMask = GetBottomRightMask(fieldId);

    auto topLeftTakeMask = GetTopLeftMask(topLeftFieldId);
    auto topRightTakeMask = GetTopRightMask(topRightFieldId);
    auto bottomLeftTakeMask = GetBottomLeftMask(bottomLeftFieldId);
    auto bottomRightTakeMask = GetBottomRightMask(bottomRightFieldId);

    BoardMap pawns;
    BoardMap queens;
    BoardMap opponentPawns;
    BoardMap opponentQueens;

    auto roundCounter = 0;
        while (true) {
            //round start
            auto wasPushedSomewhereElse = false;
            while (true) {
                CheckersState next;
                if (!fieldSubStateReadStructure.ReadNextFromStructure(next)) {
                    break;
                }
                if (topLeftMask && topLeftTakeMask) {
                    auto potentialNewSubState = next;
                    AssignSides(potentialNewSubState, pawns, queens, opponentPawns, opponentQueens, player);
                    if (CheckPawnTakeMoveForMask(fieldMask, topLeftMask, topLeftTakeMask, pawns, queens, opponentPawns, opponentQueens)) {
                        boardSubStateMap.writeStructures_[topLeftFieldId].WriteToStructure(potentialNewSubState);
                        wasPushedSomewhereElse = true;
                    }
                }
                if (topRightMask && topRightTakeMask) {
                    auto potentialNewSubState = next;
                    AssignSides(potentialNewSubState, pawns, queens, opponentPawns, opponentQueens, player);
                    if (CheckPawnTakeMoveForMask(fieldMask, topRightMask, topRightTakeMask, pawns, queens, opponentPawns, opponentQueens)) {
                        boardSubStateMap.writeStructures_[topRightFieldId].WriteToStructure(potentialNewSubState);
                        wasPushedSomewhereElse = true;
                    }
                }
                if (bottomLeftMask && bottomLeftTakeMask) {
                    auto potentialNewSubState = next;
                    AssignSides(potentialNewSubState, pawns, queens, opponentPawns, opponentQueens, player);
                    if (CheckPawnTakeMoveForMask(fieldMask, bottomLeftMask, bottomLeftTakeMask, pawns, queens, opponentPawns, opponentQueens)) {
                        boardSubStateMap.writeStructures_[bottomLeftFieldId].WriteToStructure(potentialNewSubState);
                        wasPushedSomewhereElse = true;
                    }
                }
                if (bottomRightMask && bottomRightTakeMask) {
                    auto potentialNewSubState = next;
                    AssignSides(potentialNewSubState, pawns, queens, opponentPawns, opponentQueens, player);
                    if (CheckPawnTakeMoveForMask(fieldMask, bottomRightMask, bottomRightTakeMask, pawns, queens, opponentPawns, opponentQueens)) {
                        boardSubStateMap.writeStructures_[bottomRightFieldId].WriteToStructure(potentialNewSubState);
                        wasPushedSomewhereElse = true;
                    }
                }
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

__device__ void GetLegalQueenNormalMoves(
    const unsigned &fieldId,
    LegalTakeMovesSubStateMap& boardSubStateMap,
    SubStatesPerFieldStructure& fieldSubStateReadStructure,
    ResultLegalActionSpace& boardResultActionSpace,
    Players player) {

    auto topLeftFieldId = GetTopLeftId(fieldId);
    auto topRightFieldId = GetTopRightId(fieldId);
    auto bottomLeftFieldId = GetBottomLeftId(fieldId);
    auto bottomRightFieldId = GetBottomRightId(fieldId);

    Mask fieldMask = 1 << fieldId;
    auto topLeftMask = GetTopLeftMask(fieldId);
    auto topRightMask = GetTopRightMask(fieldId);
    auto bottomLeftMask = GetBottomLeftMask(fieldId);
    auto bottomRightMask = GetBottomRightMask(fieldId);

    BoardMap pawns;
    BoardMap queens;
    BoardMap opponentPawns;
    BoardMap opponentQueens;

    CheckersState next;
    if (fieldSubStateReadStructure.ReadNextFromStructure(next)) {
        auto activeWarps = __activemask();

        auto currentDestinationFieldId = GetTopLeftId(fieldId);
        auto currentDestinationMask = GetTopLeftMask(fieldId);
        while (currentDestinationMask) {
            auto potentialNewSubState = next;
            AssignSides(potentialNewSubState, pawns, queens, opponentPawns, opponentQueens, player);
            if (CheckQueenNormalMoveForMask(fieldMask, currentDestinationMask, pawns, queens, opponentPawns, opponentQueens)) {
                boardSubStateMap.writeStructures_[currentDestinationFieldId].WriteToStructure(potentialNewSubState);
            }
        }
        __syncwarp(activeWarps);
        currentDestinationFieldId = GetTopRightId(fieldId);
        currentDestinationMask = GetTopRightMask(fieldId);
        while (currentDestinationMask) {
            auto potentialNewSubState = next;
            AssignSides(potentialNewSubState, pawns, queens, opponentPawns, opponentQueens, player);
            if (CheckQueenNormalMoveForMask(fieldMask, currentDestinationMask, pawns, queens, opponentPawns, opponentQueens)) {
                boardSubStateMap.writeStructures_[currentDestinationFieldId].WriteToStructure(potentialNewSubState);
            }
        }
        __syncwarp(activeWarps);
        currentDestinationFieldId = GetBottomLeftId(fieldId);
        currentDestinationMask = GetBottomLeftMask(fieldId);
        while (currentDestinationMask) {
            auto potentialNewSubState = next;
            AssignSides(potentialNewSubState, pawns, queens, opponentPawns, opponentQueens, player);
            if (CheckQueenNormalMoveForMask(fieldMask, currentDestinationMask, pawns, queens, opponentPawns, opponentQueens)) {
                boardSubStateMap.writeStructures_[currentDestinationFieldId].WriteToStructure(potentialNewSubState);
            }
        }
        __syncwarp(activeWarps);
        currentDestinationFieldId = GetBottomRightId(fieldId);
        currentDestinationMask = GetBottomRightMask(fieldId);
        while (currentDestinationMask) {
            auto potentialNewSubState = next;
            AssignSides(potentialNewSubState, pawns, queens, opponentPawns, opponentQueens, player);
            if (CheckQueenNormalMoveForMask(fieldMask, currentDestinationMask, pawns, queens, opponentPawns, opponentQueens)) {
                boardSubStateMap.writeStructures_[currentDestinationFieldId].WriteToStructure(potentialNewSubState);
            }
        }
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

__device__ void GetLegalPawnNormalMoves(
    const unsigned &fieldId,
    LegalTakeMovesSubStateMap& boardSubStateMap,
    SubStatesPerFieldStructure& fieldSubStateReadStructure,
    ResultLegalActionSpace& boardResultActionSpace,
    Players player) {

    auto topLeftFieldId = GetTopLeftId(fieldId);
    auto topRightFieldId = GetTopRightId(fieldId);

    Mask fieldMask = 1 << fieldId;
    auto topLeftMask = GetTopLeftMask(fieldId);
    auto topRightMask = GetTopRightMask(fieldId);

    BoardMap pawns;
    BoardMap queens;
    BoardMap opponentPawns;
    BoardMap opponentQueens;

    CheckersState next;
    if (fieldSubStateReadStructure.ReadNextFromStructure(next)) {
        auto activeWarps = __activemask();

        if (topLeftMask) {
            auto potentialNewSubState = next;
            AssignSides(potentialNewSubState, pawns, queens, opponentPawns, opponentQueens, player);
            if (CheckPawnNormalMoveForMask(fieldMask, topLeftMask, pawns, queens, opponentPawns, opponentQueens)) {
                boardSubStateMap.writeStructures_[topLeftFieldId].WriteToStructure(potentialNewSubState);
            }
        }
        __syncwarp(activeWarps);
        if (topRightMask) {
            auto potentialNewSubState = next;
            AssignSides(potentialNewSubState, pawns, queens, opponentPawns, opponentQueens, player);
            if (CheckPawnNormalMoveForMask(fieldMask, topRightMask, pawns, queens, opponentPawns, opponentQueens)) {
                boardSubStateMap.writeStructures_[topRightFieldId].WriteToStructure(potentialNewSubState);
            }
        }
        __syncwarp(activeWarps);
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

__device__ void AssignSides(
    const CheckersState &state,
    BoardMap &pawns,
    BoardMap &queens,
    BoardMap &opponentPawns,
    BoardMap &opponentQueens,
    const Players& player) {
    //does not introduce divergence because the player is the same for the entire warp
    if (player == WhitePlayer) {
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