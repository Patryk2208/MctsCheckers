//
// Created by patryk on 1/1/26.
//

#include <checkers/deviceResources/batchSimulationResults.cuh>

/*void BatchLegalActionsHost::CopyFromGpu(CudaResource<BatchLegalActionsHost> &resource) const {
    //todo
    CUDA_CHECK(cudaMemcpy(actions_, resource.get(), resource.getRawSize(), cudaMemcpyDeviceToHost));
}*/

/*void BatchResultsHost::CopyFromGpu(CudaResource<float> &d_results) const {
    //todo
    CUDA_CHECK(cudaMemcpy(results_, d_results.get(), d_results.getRawSize(), cudaMemcpyDeviceToHost));
}*/

BatchSimulationResultsResource::BatchSimulationResultsResource(size_t size) : self_(1), results_(size) {
    const BatchSimulationResultsDevice selfCopy
    {
        results_.get()
    };
    CUDA_CHECK(cudaMemcpy(self_.get(), &selfCopy, self_.getRawSize(), cudaMemcpyHostToDevice));
}
