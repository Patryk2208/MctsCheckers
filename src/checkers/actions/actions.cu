//
// Created by patryk on 12/28/25.
//

#include <cstdint>
#include <checkers/actions/actions.cuh>

D void CheckTerminal(int batchSize, const BatchSoACheckersStateHost *states, float *results, bool *terminal) {
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
#pragma nv_exec_check_disable
GLOBAL void GetLegalActions(const void* shm, const size_t batchSize, const BatchSoACheckersStateDevice *states, BatchLegalActionsDevice *actions) {
    auto ptr = reinterpret_cast<uintptr_t>(shm);
    ptr = (ptr + alignof(LegalMovesSubStateMap) - 1) & ~(alignof(LegalMovesSubStateMap) - 1);
    auto* subStateDataStructure = reinterpret_cast<LegalMovesSubStateMap*>(ptr);

    ptr += batchSize * sizeof(LegalMovesSubStateMap);
    ptr = (ptr + alignof(ResultLegalActionSpace) - 1) & ~(alignof(ResultLegalActionSpace) - 1);
    auto* resultActionSpace = reinterpret_cast<ResultLegalActionSpace*>(ptr);
    __syncthreads();

    const auto threadId = blockIdx.x * blockDim.x + threadIdx.x;
    const unsigned fieldId = threadId % FIELD_COUNT;
    const auto boardId = threadId / FIELD_COUNT; //todo wrong for many blocks

    const auto boardSubStateMap = subStateDataStructure + boardId;
    auto boardResultActionSpace = resultActionSpace + boardId;

    if (fieldId == 0) {
        *boardSubStateMap = LegalMovesSubStateMap{};
        boardSubStateMap->readStructures_ = boardSubStateMap->structures1_;
        boardSubStateMap->writeStructures_ = boardSubStateMap->structures2_;
        *boardResultActionSpace = ResultLegalActionSpace{};
    }
    boardSubStateMap->structures1_[fieldId].size_ = 0;
    boardSubStateMap->structures2_[fieldId].size_ = 0;
    __syncthreads();

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
    while (copyCounter < boardResultActionSpace->size_) {
        actions->actions_[boardId].AppendToStructure(fieldId, boardResultActionSpace->buffer_[copyCounter]);
        copyCounter += FIELD_COUNT;
    }
}