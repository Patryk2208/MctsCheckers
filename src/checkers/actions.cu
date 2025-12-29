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

__global__ void GetLegalActions(BatchSoACheckersState states) {
    auto threadId = gridDim.x * blockDim.x + threadIdx.x;
    unsigned int fieldId = threadId % 32;
    auto boardId = threadId / 32;
    Mask fieldMask = 1 << fieldId;
    auto topLeftMask = GetTopLeftMask(fieldId);
    auto topRightMask = GetTopRightMask(fieldId);
    auto bottomLeftMask = GetBottomLeftMask(fieldId);
    auto bottomRightMask = GetBottomRightMask(fieldId);

    //todo board should be stored in shared memory, or maybe in registers per field

    //we can branch the player because all threads in a warp go into the same branch
    if (states.metadata_[boardId] & 0b10000000 == WhitePlayer) {
        //we are the white player here
        //take-moves section
        BoardMap blackPawns;
        BoardMap blackQueens;
        BoardMap whitePawns;
        BoardMap whiteQueens;
        while (true) {
            while (true) {
                //todo read next state from field's data structure, remember them as local register variables
                if (topLeftMask && ((blackPawns & topLeftMask) || (blackQueens & topLeftMask))) {
                    //todo create a sub-board without the taken piece and write into the top left field's data structure
                }
                if (topRightMask && ((blackPawns & topRightMask) || (blackQueens & topRightMask))) {
                    //todo create a sub-board without the taken piece and write into the top right field's data structure
                }
                if (bottomLeftMask && ((blackPawns & bottomLeftMask) || (blackQueens & bottomLeftMask))) {
                    //todo create a sub-board without the taken piece and write into the bottom left field's data structure
                }
                if (bottomRightMask && ((blackPawns & bottomRightMask) || (blackQueens & bottomRightMask))) {
                    //todo create a sub-board without the taken piece and write into the bottom right field's data structure
                }
            }
            __syncwarp(); //sync warps here, it's nonsense, but conceptually
            //todo if all states are complete we can end those rounds, if not we continue with another round
        }

        //todo check if we found any take-moves, if yes, exit, if no, find normal moves
        //normal moves section

        //todo read state from field's data structure(should be untouched here), remember them as local register variables
        if (topLeftMask && !((blackPawns & topLeftMask) || (blackQueens & topLeftMask) || (whitePawns & topLeftMask) || (whiteQueens & topLeftMask))) {
            //todo create a board and write into the top left field's data structure as a result
        }
        if (topRightMask && !((blackPawns & topLeftMask) || (blackQueens & topLeftMask) || (whitePawns & topLeftMask) || (whiteQueens & topLeftMask))) {
            //todo create a board and write into the top right field's data structure as a result
        }
        __syncwarp();
        //todo now return the space of possible actions

    }
    else {
        //todo repeat for black player
    }
}
