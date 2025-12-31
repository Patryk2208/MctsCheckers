//
// Created by patryk on 12/27/25.
//

#include "tocpuwb/batchExecutor.cuh"
#include "../../include/checkers/actions/actions.cuh"
#include "cudaUtils/smartPointer.cuh"

CudaResource<BatchSoACheckersState> &BatchSoACheckersState::CopyToGpu(size_t size) const {
    auto d_batch = CudaResource<BatchSoACheckersState>(size , sizeof(CheckersState));

    auto row_size = size * sizeof(BoardMap);
    auto metadata_row_size = size * sizeof(BoardMapMetadata);
    CUDA_CHECK(cudaMemcpy(d_batch.get(), whiteQueens_, row_size, cudaMemcpyHostToDevice));
    CUDA_CHECK(cudaMemcpy(d_batch.get() + row_size, whitePawns_, row_size, cudaMemcpyHostToDevice));
    CUDA_CHECK(cudaMemcpy(d_batch.get() + 2 * row_size, blackQueens_, row_size, cudaMemcpyHostToDevice));
    CUDA_CHECK(cudaMemcpy(d_batch.get() + 3 * row_size, blackPawns_, row_size, cudaMemcpyHostToDevice));
    CUDA_CHECK(cudaMemcpy(d_batch.get() + 4 * row_size, metadata_, metadata_row_size, cudaMemcpyHostToDevice));
    return d_batch;
}

void BatchResults::CopyFromGpu(CudaResource<float> &d_results) {
    results_ = new float[d_results.getObjectSize()];
    CUDA_CHECK(cudaMemcpy(results_, d_results.get(), d_results.getRawSize(), cudaMemcpyDeviceToHost));
}

void BatchExecutor::Run(size_t size, BatchSoACheckersState batch, BatchResults results) {
    auto& d_batch = batch.CopyToGpu(size);
    auto d_results = CudaResource<float>(size);
    while (true) {
        //todo check if terminal or known, if so return result as float
        //todo perform a random action from GetLegalActions
    }
    results.CopyFromGpu(d_results);
}
