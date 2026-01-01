//
// Created by patryk on 1/1/26.
//

#ifndef MCTS_CHECKERS_BATCHCHECKERSTATE_CUH
#define MCTS_CHECKERS_BATCHCHECKERSTATE_CUH
#include "checkers/state.hpp"
#include "cudaUtils/smartPointer.cuh"


struct BatchSoACheckersStateHost;

struct BatchSoACheckersStateDevice {
    BoardMap* whiteQueens_;
    BoardMap* whitePawns_;
    BoardMap* blackQueens_;
    BoardMap* blackPawns_;
    BoardMapMetadata* metadata_;
};

struct BatchSoACheckersStateResource {
    CudaResource<BatchSoACheckersStateDevice> self_;
    CudaResource<BoardMap> whiteQueens_;
    CudaResource<BoardMap> whitePawns_;
    CudaResource<BoardMap> blackQueens_;
    CudaResource<BoardMap> blackPawns_;
    CudaResource<BoardMapMetadata> metadata_;

    H BatchSoACheckersStateResource(const BatchSoACheckersStateHost& c_batch, size_t size);
};

struct BatchSoACheckersStateHost {
    BoardMap* whiteQueens_;
    BoardMap* whitePawns_;
    BoardMap* blackQueens_;
    BoardMap* blackPawns_;
    BoardMapMetadata* metadata_;

    H BatchSoACheckersStateHost(const std::vector<CheckersState>& states);
    H ~BatchSoACheckersStateHost();
    //H void CopyToGpu(CudaResource<BatchSoACheckersStateDevice>& d_batch, size_t size) const;
};


#endif //MCTS_CHECKERS_BATCHCHECKERSTATE_CUH