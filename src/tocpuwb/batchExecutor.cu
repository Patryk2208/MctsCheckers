//
// Created by patryk on 12/27/25.
//

#include "tocpuwb/batchExecutor.cuh"

BatchSoACheckersState::BatchSoACheckersState(std::vector<CheckersState> &states) {
    auto size = states.size();
    whitePawns_ = new BoardMap[size];
    blackPawns_ = new BoardMap[size];
    whiteQueens_ = new BoardMap[size];
    blackQueens_ = new BoardMap[size];
    metadata_ = new BoardMapMetadata[size];
    auto i = 0;
    for (auto &state : states) {
        whitePawns_[i] = state.whitePawns_;
        blackPawns_[i] = state.blackPawns_;
        whiteQueens_[i] = state.whiteQueens_;
        blackQueens_[i] = state.blackQueens_;
        metadata_[i] = state.metadata_;
    }
}

BatchSoACheckersState::~BatchSoACheckersState() {
    delete[] whitePawns_;
    delete[] blackPawns_;
    delete[] whiteQueens_;
    delete[] blackQueens_;
    delete[] metadata_;
}

CudaResource<BatchSoACheckersState> &BatchSoACheckersState::CopyToGpu(size_t size) const {
    auto d_batch = CudaResource<BatchSoACheckersState>(size , sizeof(CheckersState));
    CUDA_CHECK(cudaMemcpy(d_batch.get(), this, d_batch.getRawSize(), cudaMemcpyHostToDevice));
    /*auto rowSize = size * sizeof(BoardMap);
    auto metadataRowSize = size * sizeof(BoardMapMetadata);
    CUDA_CHECK(cudaMemcpy(d_batch.get(), whiteQueens_, rowSize, cudaMemcpyHostToDevice));
    CUDA_CHECK(cudaMemcpy(d_batch.get() + rowSize, whitePawns_, rowSize, cudaMemcpyHostToDevice));
    CUDA_CHECK(cudaMemcpy(d_batch.get() + 2 * rowSize, blackQueens_, rowSize, cudaMemcpyHostToDevice));
    CUDA_CHECK(cudaMemcpy(d_batch.get() + 3 * rowSize, blackPawns_, rowSize, cudaMemcpyHostToDevice));
    CUDA_CHECK(cudaMemcpy(d_batch.get() + 4 * rowSize, metadata_, metadataRowSize, cudaMemcpyHostToDevice));*/
    return d_batch;
}

void BatchLegalActions::CopyFromGpu(CudaResource<BatchLegalActions> &resource) {
    CUDA_CHECK(cudaMemcpy(this, resource.get(), resource.getRawSize(), cudaMemcpyDeviceToHost));
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


void BatchExecutor::Test(size_t size, BatchSoACheckersState batch, BatchLegalActions actions) {
    auto& d_batch = batch.CopyToGpu(size);
    auto d_actions = CudaResource<BatchLegalActions>(size, sizeof(ResultLegalActionSpace));
    const auto gridSize = 1;
    const auto blockSize = 32;
    const auto shmSize = size * SharedMemorySize;
    GetLegalActions<<<gridSize, blockSize, shmSize>>>(size, d_batch.get(), d_actions.get());
    KERNEL_CHECK();
    CUDA_CHECK(cudaDeviceSynchronize());
    actions.CopyFromGpu(d_actions);
}
