//
// Created by patryk on 12/28/25.
//

#include <cstdint>
#include <checkers/actions/actions.cuh>

GLOBAL void CheckTerminal(int batchSize, BatchSoACheckersStateHost *states, float *results, bool *terminal) {
    const auto threadId = gridDim.x * blockDim.x + threadIdx.x;
    if (threadId >= batchSize) return;

    //those should be register bound for each thread(board)
    const auto whitePawns = states->whitePawns_[threadId];
    const auto blackPawns = states->blackPawns_[threadId];
    const auto whiteQueens = states->whiteQueens_[threadId];
    const auto blackQueens = states->blackQueens_[threadId];
    const auto metadata = states->metadata_[threadId];

    //simple terminal position check
    auto whiteLoses = whitePawns + whiteQueens == 0;
    auto blackLoses = blackPawns + blackQueens == 0;
    auto moveCountDraw = (metadata & 0b00001111) == 0b00001111;

    //advanced result check
    //todo calculate some position scores

    //todo write whether terminal and if so, results
}

//todo consider eliminating the IF branches with some ugly conditional numerics
GLOBAL void GetLegalActions(const size_t batchSize, const BatchSoACheckersStateDevice *states, BatchLegalActionsDevice *actions) {
    extern __shared__ char shm[];

    auto ptr = reinterpret_cast<uintptr_t>(shm);
    ptr = (ptr + alignof(LegalMovesSubStateMap) - 1) & ~(alignof(LegalMovesSubStateMap) - 1);
    auto* subStateDataStructure = reinterpret_cast<LegalMovesSubStateMap*>(ptr);

    ptr += batchSize * sizeof(LegalMovesSubStateMap);
    ptr = (ptr + alignof(ResultLegalActionSpace) - 1) & ~(alignof(ResultLegalActionSpace) - 1);
    auto* resultActionSpace = reinterpret_cast<ResultLegalActionSpace*>(ptr);

    /*const auto sharedMemory = (void*)shm;
    const auto subStateDataStructure = (LegalTakeMovesSubStateMap*)sharedMemory;
    const auto resultActionSpace = (ResultLegalActionSpace*)(sharedMemory + batchSize * sizeof(LegalTakeMovesSubStateMap));*/
    __syncthreads();

    const auto threadId = blockIdx.x * blockDim.x + threadIdx.x;
    const unsigned fieldId = threadId % 32;
    const auto boardId = threadId / 32; //todo wrong for many blocks

    if (fieldId == 0) {
        subStateDataStructure[boardId] = LegalMovesSubStateMap{};
        resultActionSpace[boardId] = ResultLegalActionSpace{};
    }
    __syncthreads();

    auto boardSubStateMap = subStateDataStructure[boardId];
    auto boardResultActionSpace = resultActionSpace[boardId];

    const CheckersState boardState
    {
        states->whitePawns_[boardId],
        states->blackPawns_[boardId],
        states->whiteQueens_[boardId],
        states->blackQueens_[boardId],
        states->metadata_[boardId]
    };

    //we are not diverging here, because each warp is one board and the player is common across fields in one board
    if (states->metadata_[boardId] & 0b10000000) {
        DiscoverActions<BlackPlayer>(fieldId, boardState, boardSubStateMap, boardResultActionSpace);
    }
    else {
        DiscoverActions<WhitePlayer>(fieldId, boardState, boardSubStateMap, boardResultActionSpace);
    }

    __syncthreads();
    auto copyCounter = fieldId;
    while (copyCounter < boardResultActionSpace.size_) {
        actions->actions_[boardId].AppendToStructure(fieldId, boardResultActionSpace.buffer_[copyCounter]);
        copyCounter++;
    }
}