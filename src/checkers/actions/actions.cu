//
// Created by patryk on 12/28/25.
//

#include <checkers/actions/actions.cuh>

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
__global__ void GetLegalActions(BatchSoACheckersState& states, int batchSize) {
    extern __shared__ void* sharedMemory;
    auto subStateDataStructure = (LegalTakeMovesSubStateMap*)sharedMemory;
    auto resultActionSpace = (ResultLegalActionSpace*)(sharedMemory + batchSize * sizeof(LegalTakeMovesSubStateMap));
    __syncthreads();

    auto threadId = gridDim.x * blockDim.x + threadIdx.x;
    unsigned int fieldId = threadId % 32;
    auto boardId = threadId / 32;

    auto boardSubStateMap = subStateDataStructure[boardId];
    auto fieldSubStateReadStructure = boardSubStateMap.readStructures_[fieldId];
    auto boardResultActionSpace = resultActionSpace[boardId];

    CheckersState boardState{};
    boardState.whitePawns_ = states.whitePawns_[boardId];
    boardState.blackPawns_ = states.blackPawns_[boardId];
    boardState.whiteQueens_ = states.whiteQueens_[boardId];
    boardState.blackQueens_ = states.blackQueens_[boardId];
    boardState.metadata_ = states.metadata_[boardId];

    //we are not diverging here, because each warp is one board and the player is common across fields in one board
    if (states.metadata_[boardId] & 0b10000000) {
        DiscoverActions<BlackPlayer>(fieldId, boardState, boardSubStateMap, fieldSubStateReadStructure, boardResultActionSpace);
    }
    else {
        DiscoverActions<WhitePlayer>(fieldId, boardState, boardSubStateMap, fieldSubStateReadStructure, boardResultActionSpace);
    }

    __syncwarp();
    //todo now return the space of possible actions

}

template<Players player>
__device__ void InitializeDataStructure(
    const unsigned &fieldId,
    const CheckersState& state,
    LegalTakeMovesSubStateMap& boardSubStateMap) {
    auto fieldMask = 1 << fieldId;
    if constexpr (player == WhitePlayer) {
        if (state.whitePawns_ & fieldMask || state.whiteQueens_ & fieldMask) {
            boardSubStateMap.writeStructures_[fieldId].WriteToStructure(state);
        }
    }
    else {
        if (state.blackPawns_ & fieldMask || state.blackQueens_ & fieldMask) {
            boardSubStateMap.writeStructures_[fieldId].WriteToStructure(state);
        }
    }
    boardSubStateMap.SwapDataStructures();
}

template<Players player>
__device__ void DiscoverActions(
    const unsigned &fieldId,
    const CheckersState& originalState,
    LegalTakeMovesSubStateMap& boardSubStateMap,
    SubStatesPerFieldStructure& fieldSubStateReadStructure,
    ResultLegalActionSpace& boardResultActionSpace) {

    //take-moves section
    InitializeDataStructure<player>(fieldId, originalState, boardSubStateMap);
    GetLegalQueenTakeMoves<player>(fieldId, boardSubStateMap, fieldSubStateReadStructure, boardResultActionSpace);

    InitializeDataStructure<player>(fieldId, originalState, boardSubStateMap);
    GetLegalPawnTakeMoves<player>(fieldId, boardSubStateMap, fieldSubStateReadStructure, boardResultActionSpace);
    if (boardResultActionSpace.size_ == 0) {
        //normal moves section
        InitializeDataStructure<player>(fieldId, originalState, boardSubStateMap);
        GetLegalQueenNormalMoves<player>(fieldId, boardSubStateMap, fieldSubStateReadStructure, boardResultActionSpace);

        InitializeDataStructure<player>(fieldId, originalState, boardSubStateMap);
        GetLegalPawnNormalMoves<player>(fieldId, boardSubStateMap, fieldSubStateReadStructure, boardResultActionSpace);
    }
}