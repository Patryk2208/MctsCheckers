//
// Created by patryk on 1/1/26.
//

#ifndef MCTS_CHECKERS_BATCHSIMULATIONRESULTS_CUH
#define MCTS_CHECKERS_BATCHSIMULATIONRESULTS_CUH
#include "cudaUtils/cudaCompatibility.hpp"
#include "cudaUtils/smartPointer.cuh"


struct BatchSimulationResultsDevice {
    float* results_;
};

struct BatchSimulationResultsResource {
    CudaResource<BatchSimulationResultsDevice> self_;
    CudaResource<float> results_;

    H BatchSimulationResultsResource(size_t size);
};

struct BatchSimulationResultsHost {
    float* results_;

    //H void CopyFromGpu(CudaResource<float>& d_results) const;
};

#endif //MCTS_CHECKERS_BATCHSIMULATIONRESULTS_CUH