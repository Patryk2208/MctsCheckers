//
// Created by patryk on 1/1/26.
//

#include <checkers/deviceResources/batchActionSpace.cuh>

H BatchLegalActionsResource::BatchLegalActionsResource(const size_t size) : self_(1), actions_(size) {
    const BatchLegalActionsDevice selfCopy
    {
        actions_.get()
    };
    CUDA_CHECK(cudaMemcpy(self_.get(), &selfCopy, self_.getRawSize(), cudaMemcpyHostToDevice));
}

H BatchLegalActionsHost::BatchLegalActionsHost(const size_t size) {
    actions_ = new ResultLegalActionSpace[size];
}

H BatchLegalActionsHost::~BatchLegalActionsHost() {
    delete[] actions_;
}

void BatchLegalActionsHost::CopyFromGpu(BatchLegalActionsResource &resource) {
    CUDA_CHECK(cudaMemcpy(actions_, resource.actions_.get(), resource.actions_.getRawSize(), cudaMemcpyDeviceToHost));
}

