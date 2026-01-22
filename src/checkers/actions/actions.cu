//
// Created by patryk on 12/28/25.
//

#include <cstdint>
#include <checkers/actions/actions.cuh>

#define QUEEN_MATERIAL_VALUE 3.0f
#define PAWN_MATERIAL_VALUE 1.0f
#define MATERIAL_ADVANTAGE_THRESHOLD 5.0f

D void CheckTerminal(size_t batchSize, const BatchSoACheckersStateDevice *states, const BatchSimulationResultsDevice* results, bool* terminal) {
    const auto threadId = blockIdx.x * blockDim.x + threadIdx.x;
    const auto boardId = threadId / FIELD_COUNT;
    const auto fieldId = threadId % FIELD_COUNT;
    if (boardId >= batchSize) return;

    auto isGameEnded = false;
    if (fieldId == 0) {
        //those should be register bound for each thread(board)
        const auto wp = states->whitePawns_[boardId];
        const auto bp = states->blackPawns_[boardId];
        const auto wq = states->whiteQueens_[boardId];
        const auto bq = states->blackQueens_[boardId];
        const auto m = states->metadata_[boardId];
        const auto isWhiteToMove = m & 256;
        auto result = 0.0f;

        //simple terminal position check
        auto whiteWins = (bp || bq) == 0;
        auto blackWins = (wp || wq) == 0;
        auto moveCountDraw = (m & 0b00001111) == 0b00001111;

        //advanced result check
        auto w_material = __popc(wp) * PAWN_MATERIAL_VALUE + __popc(wq) * QUEEN_MATERIAL_VALUE;
        auto b_material = __popc(bp) * PAWN_MATERIAL_VALUE + __popc(bq) * QUEEN_MATERIAL_VALUE;

        if (whiteWins || w_material - b_material >= MATERIAL_ADVANTAGE_THRESHOLD) {
            result = isWhiteToMove ? 1.0f : -1.0f;
            isGameEnded = true;
        }
        if (blackWins || b_material - w_material >= MATERIAL_ADVANTAGE_THRESHOLD) {
            result = isWhiteToMove ? -1.0f : 1.0f;
            isGameEnded = true;
        }
        if (moveCountDraw) {
            result = 0.0f;
            isGameEnded = true;
        }
        results->results_[boardId] = result;
    }
    isGameEnded = __shfl_sync(0xffffffff, isGameEnded, 0);
    *terminal = isGameEnded;
}

//todo consider eliminating the IF branches with some ugly conditional numerics
#pragma nv_exec_check_disable
D void GetLegalActions(const void* shm, const size_t batchSize, const BatchSoACheckersStateDevice *states, const BatchLegalActionsDevice *actions) {
    const auto threadId = blockIdx.x * blockDim.x + threadIdx.x;
    const auto fieldId = threadId % FIELD_COUNT;
    const auto boardId = threadId / FIELD_COUNT;
    if (boardId >= batchSize) return;
    const auto boardsPerBlock = blockDim.x / FIELD_COUNT;
    const auto boardIdInBlock = boardId % boardsPerBlock;

    auto ptr = reinterpret_cast<uintptr_t>(shm);
    ptr = (ptr + alignof(LegalMovesSubStateMap) - 1) & ~(alignof(LegalMovesSubStateMap) - 1);
    auto* subStateDataStructure = reinterpret_cast<LegalMovesSubStateMap*>(ptr);

    ptr += boardsPerBlock * sizeof(LegalMovesSubStateMap);
    ptr = (ptr + alignof(ResultLegalActionSpace) - 1) & ~(alignof(ResultLegalActionSpace) - 1);
    auto* resultActionSpace = reinterpret_cast<ResultLegalActionSpace*>(ptr);
    __syncthreads();

    const auto boardSubStateMap = subStateDataStructure + boardIdInBlock;
    auto boardResultActionSpace = resultActionSpace + boardIdInBlock;

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
    if (boardState.metadata_ & 0b10000000) {
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