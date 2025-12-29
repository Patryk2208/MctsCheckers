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

__device__ Mask GetTopLeftMask(unsigned int fieldId) {
    //todo
}

__device__ Mask GetTopRightMask(unsigned int fieldId) {
    //todo
}

__device__ Mask GetBottomLeftMask(unsigned int fieldId) {
    //todo
}

__device__ Mask GetBottomRightMask(unsigned int fieldId) {
    //todo
}

//todo consider eliminating the IF branches with some ugly conditional numerics
//todo perhaps it's possible to split into 4 phases queen take, pawn take, queen move, pawn move
__global__ void GetLegalActions(BatchSoACheckersState& states, int batchSize) {
    extern __shared__ void* sharedMemory;
    auto subStateDataStructure = (LegalTakeMovesSubStateMap*)sharedMemory;
    auto resultActionSpace = (ResultLegalActionSpace*)(sharedMemory + batchSize * sizeof(LegalTakeMovesSubStateMap));
    //todo shm init
    __syncthreads();

    auto threadId = gridDim.x * blockDim.x + threadIdx.x;
    unsigned int fieldId = threadId % 32;
    auto boardId = threadId / 32;

    Mask fieldMask = 1 << fieldId;
    auto topLeftFieldId = GetTopLeftId(fieldId);
    auto topRightFieldId = GetTopRightId(fieldId);
    auto bottomLeftFieldId = GetBottomLeftId(fieldId);
    auto bottomRightFieldId = GetBottomRightId(fieldId);
    auto topLeftMask = GetTopLeftMask(fieldId);
    auto topRightMask = GetTopRightMask(fieldId);
    auto bottomLeftMask = GetBottomLeftMask(fieldId);
    auto bottomRightMask = GetBottomRightMask(fieldId);

    auto boardSubStateMap = subStateDataStructure[boardId];
    auto fieldSubStateReadStructure = boardSubStateMap.readStructures_[fieldId];
    auto boardResultActionSpace = resultActionSpace[boardId];

    //todo first we wanna populate the readStructures somehow

    //we can branch the player because all threads in a warp go into the same branch
    if (states.metadata_[boardId] & 0b10000000 == WhitePlayer) {
        //we are the white player here
        //take-move section for queens
        auto roundCounter = 0;
        while (true) {
            //round start
            auto wasPushedSomewhereElse = false;
            while (true) {
                CheckersState next;
                if (!fieldSubStateReadStructure.ReadNextFromStructure(next)) {
                    break;
                }
                if (topLeftMask) {
                    //todo check all fields in top left direction
                }
                if (topRightMask) {
                    //todo check all fields in top right direction
                }
                if (bottomLeftMask) {
                    //todo check all fields in bottom left direction
                }
                if (bottomRightMask) {
                    //todo check all fields in bottom right direction
                }
                if (!wasPushedSomewhereElse && roundCounter > 0) {
                    CompleteQueenMoveFromSubTakeMoveState(next);
                    boardResultActionSpace.AppendToStructure(next);
                }
            }
            //todo setup the data structure after the round
            if (!__any_sync(0xffffffff, wasPushedSomewhereElse)) break;
            ++roundCounter;
        }

        //take-moves section for pawns
        roundCounter = 0;
        while (true) {
            //round start
            auto wasPushedSomewhereElse = false;
            while (true) {
                CheckersState next;
                if (!fieldSubStateReadStructure.ReadNextFromStructure(next)) {
                    break;
                }
                if (topLeftMask) {
                    auto potentialNewSubState = next;
                    if (CheckPawnTakeMoveForMask(TODO, TODO, topLeftMask, TODO, TODO, TODO, potentialNewSubState.blackPawns_, potentialNewSubState.blackQueens_)) {
                        boardSubStateMap.writeStructures_[topLeftFieldId].WriteToStructure(potentialNewSubState);
                        wasPushedSomewhereElse = true;
                    }
                }
                if (topRightMask) {
                    auto potentialNewSubState = next;
                    if (CheckPawnTakeMoveForMask(TODO, TODO, topRightMask, TODO, TODO, TODO, potentialNewSubState.blackPawns_, potentialNewSubState.blackQueens_)) {
                        boardSubStateMap.writeStructures_[topRightFieldId].WriteToStructure(potentialNewSubState);
                        wasPushedSomewhereElse = true;
                    }
                }
                if (bottomLeftMask) {
                    auto potentialNewSubState = next;
                    if (CheckPawnTakeMoveForMask(TODO, TODO, bottomLeftMask, TODO, TODO, TODO, potentialNewSubState.blackPawns_, potentialNewSubState.blackQueens_)) {
                        boardSubStateMap.writeStructures_[bottomLeftFieldId].WriteToStructure(potentialNewSubState);
                        wasPushedSomewhereElse = true;
                    }
                }
                if (bottomRightMask) {
                    auto potentialNewSubState = next;
                    if (CheckPawnTakeMoveForMask(TODO, TODO, bottomRightMask, TODO, TODO, TODO, potentialNewSubState.blackPawns_, potentialNewSubState.blackQueens_)) {
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

        if (boardResultActionSpace.size_ == 0) {
            //normal moves section
            //todo we might wanna repopulate the read structure and clear structures altogether

            //queen normal moves
            CheckersState next;
            fieldSubStateReadStructure.ReadNextFromStructure(next);

            if (topLeftMask) {
                //todo check all queen moves in top left diagonal
            }
            if (topRightMask) {
                //todo check all queen moves in top right diagonal
            }
            if (topLeftMask) {
                //todo check all queen moves in bottom left diagonal
            }
            if (topRightMask) {
                //todo check all queen moves in bottom right diagonal
            }
            //todo setup the data structure after the round
            __syncwarp(0xffffffff);
            while (true) {
                if (!fieldSubStateReadStructure.ReadNextFromStructure(next)) {
                    break;
                }
                boardResultActionSpace.AppendToStructure(next);
            }

            //pawn normal moves
            fieldSubStateReadStructure.ReadNextFromStructure(next);

            if (topLeftMask) {
                auto potentialNewSubState = next;
                if (CheckPawnNormalMoveForMask(TODO, topLeftMask, potentialNewSubState)) {
                    boardSubStateMap.writeStructures_[topLeftFieldId].WriteToStructure(potentialNewSubState);
                }
            }
            if (topRightMask) {
                auto potentialNewSubState = next;
                if (CheckPawnNormalMoveForMask(TODO, topRightMask, potentialNewSubState)) {
                    boardSubStateMap.writeStructures_[topRightFieldId].WriteToStructure(potentialNewSubState);
                }
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
        __syncwarp();
        //todo now return the space of possible actions

    }
    else {
        //todo repeat for black player
    }
}

//helper functions
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