//
// Created by patryk on 1/1/26.
//

#include <checkers/deviceResources/batchCheckerState.cuh>

BatchSoACheckersStateHost::BatchSoACheckersStateHost(const std::vector<CheckersState> &states) {
    auto size = states.size();
    whitePawns_ = new BoardMap[size];
    blackPawns_ = new BoardMap[size];
    whiteQueens_ = new BoardMap[size];
    blackQueens_ = new BoardMap[size];
    metadata_ = new BoardMapMetadata[size];
    for (auto i = 0; i < size; ++i) {
        const auto& state = states[i];
        whitePawns_[i] = state.whitePawns_;
        blackPawns_[i] = state.blackPawns_;
        whiteQueens_[i] = state.whiteQueens_;
        blackQueens_[i] = state.blackQueens_;
        metadata_[i] = state.metadata_;
    }
}

BatchSoACheckersStateHost::~BatchSoACheckersStateHost() {
    delete[] whitePawns_;
    delete[] blackPawns_;
    delete[] whiteQueens_;
    delete[] blackQueens_;
    delete[] metadata_;
}

H BatchSoACheckersStateResource::BatchSoACheckersStateResource(const BatchSoACheckersStateHost &c_batch, const size_t size)
    : self_(1), whiteQueens_(size), whitePawns_(size), blackQueens_(size), blackPawns_(size), metadata_(size) {
    const auto rowSize = size * sizeof(BoardMap);
    const auto metadataRowSize = size * sizeof(BoardMapMetadata);
    CUDA_CHECK(cudaMemcpy(whiteQueens_.get(), c_batch.whiteQueens_, rowSize, cudaMemcpyHostToDevice));
    CUDA_CHECK(cudaMemcpy(whitePawns_.get(), c_batch.whitePawns_, rowSize, cudaMemcpyHostToDevice));
    CUDA_CHECK(cudaMemcpy(blackQueens_.get(), c_batch.blackQueens_, rowSize, cudaMemcpyHostToDevice));
    CUDA_CHECK(cudaMemcpy(blackPawns_.get(), c_batch.blackPawns_, rowSize, cudaMemcpyHostToDevice));
    CUDA_CHECK(cudaMemcpy(metadata_.get(), c_batch.metadata_, metadataRowSize, cudaMemcpyHostToDevice));

    const BatchSoACheckersStateDevice selfCopy
    {
        whiteQueens_.get(),
        whitePawns_.get(),
        blackQueens_.get(),
        blackPawns_.get(),
        metadata_.get()
    };

    CUDA_CHECK(cudaMemcpy(self_.get(), &selfCopy, self_.getRawSize(), cudaMemcpyHostToDevice));
}
