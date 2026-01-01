//
// Created by patryk on 1/1/26.
//

#ifndef MCTS_CHECKERS_BATCHACTIONSPACE_CUH
#define MCTS_CHECKERS_BATCHACTIONSPACE_CUH
#include "checkers/actions/shmStructure.cuh"
#include "cudaUtils/cudaCompatibility.hpp"
#include "cudaUtils/smartPointer.cuh"


struct BatchLegalActionsDevice {
    ResultLegalActionSpace* actions_;
};

struct BatchLegalActionsResource {
    CudaResource<BatchLegalActionsDevice> self_;
    CudaResource<ResultLegalActionSpace> actions_;

    H BatchLegalActionsResource(size_t size);
};

struct BatchLegalActionsHost {
    ResultLegalActionSpace* actions_;

    H BatchLegalActionsHost(size_t size);
    H ~BatchLegalActionsHost();
    //H void CopyFromGpu(CudaResource<BatchLegalActionsDevice>& resource) const;
};


#endif //MCTS_CHECKERS_BATCHACTIONSPACE_CUH