//
// Created by patryk on 1/1/26.
//

#include <checkers/deviceResources/batchSimulationResults.cuh>

BatchSimulationResultsResource::BatchSimulationResultsResource(size_t size) : self_(1), results_(size) {
    const BatchSimulationResultsDevice selfCopy
    {
        results_.get()
    };
    CUDA_CHECK(cudaMemcpy(self_.get(), &selfCopy, self_.getRawSize(), cudaMemcpyHostToDevice));
}

BatchSimulationResultsHost::BatchSimulationResultsHost(size_t size) {
    results_ = new float[size];
}

BatchSimulationResultsHost::~BatchSimulationResultsHost() {
    delete[] results_;
}

void BatchSimulationResultsHost::CopyFromGpu(BatchSimulationResultsResource &resource) const {
    CUDA_CHECK(cudaMemcpy(results_, resource.results_.get(), resource.results_.getRawSize(), cudaMemcpyDeviceToHost));
}
